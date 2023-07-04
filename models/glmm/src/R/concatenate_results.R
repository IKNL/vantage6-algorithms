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
#' @export
#'
concatenate_results <- function(start,
                                local_eval,
                                client,
                                family,
                                nAGQ,
                                formula){

    # vtg::log$debug("Collecting partial results from nodes...")

    mixeff <- unlist(start, use.names = T)

    len.mix.eff <- length(unlist(start, use.names = F))

    vtg::log$debug("Running GLM on fixed effects to find init params...")

    # fe_term_init <- client$call("initparams", formula_str=formula, family=family)

    # contributers <- seq(length(fe_term_init))

    # fe_term_init <- Reduce(`mean`, lapply(contributers, function(i){
        # fe_term_init}))

    nodes <- client$call(local_eval, start = start,
        family=family, formula=formula,
        nAGQ=nAGQ)

    contributers <- seq(length(nodes))

    vtg::log$debug("Summing partials to update mixed effects...")

    deviance <- Reduce(`+`, lapply(contributers, function(i) nodes[[i]][1]))

    gradient <- Reduce(`+`, lapply(contributers, function(i) attr(nodes[[i]],
                                                                  "gradient")))

    hessian <- Reduce(`+`, lapply(contributers, function(i) attr(nodes[[i]],
                                                                 "hessian")))

    intercepts <- Reduce(`c`, lapply(contributers, function(i)
        attr(nodes[[i]], "intercepts")))

    number_of_groups <- Reduce(`+`, lapply(contributers, function(i)
        attr(nodes[[i]], "number_of_groups")))

    cond_mode_u <- Reduce(`c`, lapply(contributers, function(i)
        attr(nodes[[i]], "conditional_mode_spherical_ranef")))

    cond_mode_b <- Reduce(`c`, lapply(contributers, function(i)
        attr(nodes[[i]], "condtional_mode_ranef")))

    ME <- lapply(contributers, function(i) {
        lapply(attr(nodes[[i]], "ME"), function(j) j[1])
    })

    fe_assertion <- all.equal(unlist(lapply(ME, function(i) i$N_fe)),
                              unlist(lapply(ME, function(i) i$N_fe)))
    re_assertion <- all.equal(unlist(lapply(ME, function(i) i$N_re)),
                              unlist(lapply(ME, function(i) i$N_re)))

    if(!isTRUE(all(c(fe_assertion, re_assertion)))){
        stop("The number of random effects and fixed effects must be the same
             at each site.")
    }

    res <- deviance

    attr(res, "gradient") <- gradient

    attr(res, "hessian") <- hessian

    vtg::set.option("intercepts", intercepts)

    vtg::set.option("number_of_groups", number_of_groups)

    vtg::set.option("u", cond_mode_u)

    vtg::set.option("b", cond_mode_b)

    vtg::set.option("N_re", unique(unlist(lapply(ME, function(i) i$N_re))))

    vtg::set.option("N_fe", unique(unlist(lapply(ME, function(i) i$N_fe))))

    return(res)
}
