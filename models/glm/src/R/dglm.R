#' Run the federated GLM.
#'
#' @param client vtg::Client instance
#' @param formula an object of class formula (or one that can be coerced to that
#' class: a symbolic description of the model to be fitted. E.g.:
#' dependant_variable ~ explanatory_variable(i) + ...
#' @param dstar ...
#' @param types types of the columns that are used in the formula
#' @param family: to this up it uses the Gaussian as this is the default value
#' @param tol: tolerance level
#' @param maxit: maximum number of iterations
#'
#' @return A GLM model in a dict format. To convert it to a GLM model which
#' can be used by R, use the `vtg.glm::as.GLM(output)` to convert it.
#'
dglm <- function(client, formula, dstar=NULL, types=NULL, family = gaussian,
                 tol = 1e-08, maxit = 25) {

    vtg::log$debug("Initializing...")

    USE_VERBOSE_OUTPUT <- getOption('vtg.verbose_output', T)
    lgr::threshold("debug")


    # Run in a MASTER container. Note that this will call this method but then
    # within a Docker container. The client used here bellow has set the
    # property `use.master.container` set to `False`, therefore it will skip
    # this block (else an infinite loop would occur).
    if (client$use.master.container) {
        vtg::log$debug(glue::glue("Running `dglm` in master container using
                                  image '{image.name}'.."))
        result <- client$call("dglm", formula=formula, dstar=dstar, types=types,
                              family=family, tol=tol, maxit=maxit)
        return(result)
    }

    # Collect all parameters in a single var which can be passed arround the
    # methods.
    params <- list(formula = formula, types=types, dstar=dstar, family = family,
                   iter = 1, tol = tol, maxit = maxit)

    # Loop until the model is converged or when `max_it` has been hit. Note that
    # the maximum itterations are checked in `master_deviance`.
    repeat{

        vtg::log$info(glue::glue("{params$iter}.1 - RPC Node Beta"))
        results <- client$call("node_beta", master = params)

        vtg::log$debug(glue::glue("  length of results = {length(results)}"))
        Ds <- lapply(results, as.data.frame)

        vtg::log$info("{params$iter}.2 - Master beta")
        params <- vtg.glm::master_beta(master= params, nodes = results)

        vtg::log$info(glue::glue("{params$iter}.3 - RPC Node Deviance"))
        results <- client$call("node_deviance", master = params)
        Ds <- lapply(results, as.data.frame)

        vtg::log$info("{params$iter}.4 - Master deviance")
        params <- vtg.glm::master_deviance(nodes = results, master = params)

        vtg::log$info("{params$iter}.5 - Check convergence")
        if (params$converged) {
            vtg::log$debug("  Model converged or Maximum iterations reached")
            break
        }
    }

    # Return
    params
}