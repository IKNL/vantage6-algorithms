#' Federated GLM
#'
#' @param client vtg::Client instance, profided by the node
#' @param formula an object of class formula (or one that can be coerced
#'   to that class: a symbolic description of the model to be fitted.
#'   E.g.: dependant_variable ~ explanatory_variable(i) + ...
#' @param dstar name of the dstar sensor column (e.g. expected deaths).
#'  Only applicable when using the glm relative survival model with
#'  Poisson regression)
#' @param types types of the columns that are used in the formula
#' @param family family type, Gaussian is used by default
#' @param tol tolerance level
#' @param maxit maximum number of iterations
#'
#' @return A GLM model in a dict format. To convert it to a GLM model which
#'  can be used by R, use the `vtg.glm::as.GLM(output)` to convert it.
#'
#' @author Cellamare, M.
#' @author Martin, F.
#' @author van Gestel, A.
#'
dglm <- function(client, formula, dstar=NULL, types=NULL, family=gaussian,
                 tol=1e-08, maxit=25) {

    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

    # Parse a string to formula type. If it already is a formula this statement
    # will do nothing. This is needed when Python (or other langauges) is used
    # as a client.
    formula <- as.formula(formula)

    # Run in a MASTER container. Note that this will call this method but then
    # within a Docker container. The client used here below has set the
    # property `use.master.container` set to `False`, therefore it will skip
    # this block (else an infinite loop would occur).
    if (client$use.master.container) {
        vtg::log$debug(glue::glue("Running `dglm` in master container using
                                  image '{image.name}'.."))
        result <- client$call(
            "dglm",
            formula = formula,
            dstar = dstar,
            types = types,
            family = family,
            tol = tol,
            maxit = maxit
        )

        return(result)
    }

    # initialization variables
    coeff <- NULL
    coeff_old <- NULL
    iter <- 0

    # Loop until the model is converged or when `maxit` has been hit.
    repeat{

        #######################################################################
        # RPC NODE BETA - COMPUTE BETA PARTIALS
        #######################################################################
        # Compute C^1 (=v1) and C^2 (=v2) for each node
        vtg::log$info("{iter}.1 - RPC Node Beta")
        beta_partials <- client$call(
            "node_beta",
            formula = formula,
            family = family,
            first_iteration = (iter == 0),
            dstar = dstar,
            coeff = coeff,
            types = types
        )
        vtg::log$debug("  - [DONE]")

        #######################################################################
        # CENTRAL - COMPUTE BETAS
        #######################################################################
        # compute X^T W X by summing C^1 from all nodes, and compute
        # X^T W z by summing all C^2 from all nodes. Then update the
        # betas accordingly
        vtg::log$info("{iter}.2 - Master beta")
        beta <- vtg.glm::master_beta(
            partials = beta_partials,
            family = family,
            dstar = dstar
        )
        vtg::log$debug("  - [DONE]")

        # update the coefficients, and keep the coefficients of the
        # previous iteration
        coeff_old <- coeff
        coeff <- beta$coef

        #######################################################################
        # RPC NODE DEVIANCE - COMPUTE PARTIAL DEVS
        #######################################################################
        # compute dev for each of the individual nodes
        vtg::log$info("{iter}.3 - RPC Node Deviance")
        deviance_partials <- client$call(
            "node_deviance",
            formula = formula,
            family = family,
            first_iteration = (iter == 0),
            dstar = dstar,
            coeff = coeff,
            coeff_old = coeff_old,
            wtdmu = beta$wtdmu,
            types = types
        )
        vtg::log$debug("  - [DONE]")

        #######################################################################
        # CENTRAL - SUM DEV
        #######################################################################
        vtg::log$info("{iter}.4 - Master deviance")
        deviance <- vtg.glm::master_deviance(
            partials = deviance_partials,
            family = family,
            dstar = dstar
        )
        vtg::log$debug("  - [DONE]")

        vtg::log$info("{iter}.5 - Termination conditions")
        # Evaluate if algorithm  converge
        converged <- (abs(deviance$dev - deviance$dev_old) /
            (0.1 + abs(deviance$dev)) < tol)
        exceeded_iter <- (iter >= maxit)

        print(deviance$dev_old)
        if (converged | exceeded_iter) {
            if (converged) vtg::log$debug("  - [CONVERGED]")
            if (exceeded_iter) vtg::log$debug("  - [EXCEEDED N. ITERATIONS]")
            break
        }
        vtg::log$debug("  - [DONE]")
        iter <- iter + 1
    }

    #######################################################################
    # CENTRAL - FINALIZING RESULTS
    #######################################################################
    vtg::log$debug("Preparing output")

    zvalue <- coeff[, 1] / beta$se
    if (beta$est_disp) {
        pvalue <- 2 * pt(-abs(zvalue), beta$nobs - beta$nvars)
    } else {
        pvalue <- 2 * pnorm(-abs(zvalue))
    }

    # collecting output
    output <- list(
        converged = converged,
        coefficients = as.pairlist(coeff[, 1]),
        Std.Error = as.pairlist(beta$se),
        pvalue = as.pairlist(pvalue),
        zvalue = as.pairlist(zvalue),
        dispersion = beta$disp,
        est.disp = beta$est_disp,
        formula = formula,
        family =  vtg.glm::get_family(family = family, dstar = dstar),
        iter = iter,
        deviance = deviance,
        null.deviance = deviance$dev_null,
        nobs = beta$nobs,
        nvars = beta$nvars
    )

    # Return, formula is not parsed to json (if this is requested). When using
    # RDS this is not an issue.
    return(output)
}
