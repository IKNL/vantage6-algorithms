#' "Server-side" function that collects partial results from the individual
#' nodes.
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
#' @param vtg::Client instance, provided by the node
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
#' @return Concatenation of all local deviance's as well as their gradient and
#' hessian attributes.
#'
#' This function is the precursor to the `vtg.glmm::glmm` function.
#'
concatenate_results <- function(start,
                                local_eval,
                                client,
                                family,
                                nAGQ,
                                formula){

    vtg::log$debug("Collecting partial results from local sites...")


    len.mix.eff <- length(unlist(start, use.names = F))

    # family <- get_family(family)

    nodes <- client$call(local_eval, start=start, family=family,
                         formula=formula, nAGQ=nAGQ)

    # dev <- 0
    # grad <- rep(0, len.mix.eff)
    # hess <- matrix(0, len.mix.eff, len.mix.eff)
    # nobs <- 0
    # r.e <- list()

    contributers <- seq(length(nodes))

    vtg::log$debug("Concatenating partial calculations to update mixed effects...")


    # first collect all the results from each site
    # for (j in 1:length(nodes)){
    #
    #     temp.site <- nodes[[j]]
    #
    #     deviance <- dev +  temp.site
    #
    #     gradient <- grad + attr(temp.site, "gradient")
    #
    #     hessian <- hess + attr(temp.site, "hessian")
    #
    #     nobs <- nobs + attr(temp.site, "nobs")
    #
    #     r.e[[j]] <- attr(temp.site, "r.e")
    # }

    deviance <- Reduce(`+`, lapply(contributers, function(i) nodes[[i]][1]))

    gradient <- Reduce(`+`, lapply(contributers, function(i) attr(nodes[[i]],
                                                                  "gradient")))

    hessian <- Reduce(`+`, lapply(contributers, function(i) attr(nodes[[i]],
                                                                 "hessian")))

    nobs <- Reduce(`+`, lapply(contributers, function(i) attr(nodes[[i]],
                                                              "nobs")))

    r.e <- 0

    # For now the correct family

    family <- attr(nodes, "family")

    r.e <- sapply(unlist(r.e), unique)

    res <- deviance

    attr(res, "gradient") <- gradient
    attr(res, "hessian") <- hessian
    # attr(res)
    ### for now this needs to change desperately ###
    assign("nobs", nobs, envir = .GlobalEnv)
    assign("unique raneff levels", r.e, envir = .GlobalEnv)
    assign("number of groups", length(r.e), envir = .GlobalEnv)

    return(res)
}
