#' Federated Generalized Mixed Effect Function.
#'
#' Collects all the partial values of the deviance from each site via
#' vtg.glmm::concatenate_results then
#'
#' @param vtg::Client instance, provided by the node
#'
#' @param start List of starting values for the Random Effect Term and the
#' Fixed Effect Term(s). Note that one should invoke the list in the following
#' manner: start = list(theta = x, fixef = y) where `x` is a single value, and
#' `y` can be a vector of starting values depending on how many fixed effects
#' are included in the model.
#'
#' @param local_eval String, RPC call to run a single iteration of
#' the `lme4::glmer` function. This evaluates the deviance at the supplied set
#' of starting values given by the `start` parameter via the Adaptive Gauss
#' Hermite Quadrature Scheme.
#'
#' @param family Family type, if non is supplied then Gaussian Family is used.
#'
#' @param nAGQ Integer Scalar of the number of points per axis for evaluating
#' the Adaptive Gauss Hermite Quadrature approximation to the log-likelihood.
#' The default number we take is 10, but this can go up to 25 or as few as 1.
#' The latter will simply be the Laplace Approximation of the Deviance.
#'
#' @param formula A two-sided linear formula object describing both the fixed
#' effects and random effect parts of the model. The response parameter must be
#' on the left hand side of a '~' operator and the independent variables that
#' follow must be separated with a '+' operator. The random effect term must
#' be distinguished by a vertical bar '|'.
#'
#' @return A list object from which
glmm <- function(client,
                 start,
                 local_eval,
                 family,
                 nAGQ,
                 formula){

    lgr::threshold('debug')
    vtg::log$debug("Starting...")
    mixeff <- as.vector(unlist(start, use.names = F))

    family <- get_family(family)

    vtg::log$debug("Using nlm to optimize GLMM...")
    res <- nlm(f = vtg.glmm::concatenate_results, p=mixeff,
               client = client, local_eval = local_eval,
               formula=formula, family = family, nAGQ = nAGQ,
               hessian = TRUE, iterlim = 10000,
               gradtol = 1e-10, steptol = 1e-10, check.analyticals = T)
    res$'variance.covariance' <- solve(0.5*res$hessian)

    vtg::log$debug("Collected local deviance...")

    res$'Family' <- family$family
    res$'Link' <- family$link
    res$'Formula' <- Reduce(paste, deparse(formula))
    res$'nAGQ' <- nAGQ
    res$'nobs' <- get("nobs", envir = -1)
    res$'groups' <- get("number of groups", envir = -1)

    len.coef <- length(res$estimate)

    if(!is.language(formula)){
        formula = formula(formula)
    }

    list.of.pars <- mkParsTemplate(formula)
    fixed_effects = as.table(res$estimate[2:len.coef])
    rownames(fixed_effects) = names(list.of.pars$beta)
    random_effect  <- as.table(res$estimate[1])
    rownames(random_effect) <- names(list.of.pars$theta)
    names.ran.eff <- as.character(findbars(formula)[[1]][[3]])
    names.fix.eff <- names(list.of.pars$beta[-1])

    output <- list(
        paste("Generalized linear mixed model fit by minimized deviance",
              sprintf("(Adaptive Gauss-Hermite Quadrature, nAGQ = %d)", nAGQ)),
        deviance = res$minimum,
        fixed_effects = fixed_effects,
        random_effect = random_effect,
        gradient = res$gradient,
        hessian = res$hessian,
        variance_covariance = res$variance.covariance,
        formula = res$Formula,
        family = res$Family,
        link = res$Link,
        nlm_code = res$code,
        iterations = res$iterations,
        number_of_obs = res$nobs,
        ran_eff_groups = res$groups
    )
    return(output)

    vtg::log$debug("Finalized...")
    # return(res)
}
