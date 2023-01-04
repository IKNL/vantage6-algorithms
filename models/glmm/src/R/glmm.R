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
#'
#' @export
#'
glmm <- function(client,
                 start,
                 local_eval,
                 family,
                 nAGQ,
                 formula){

    lgr::threshold('debug')

    vtg::log$debug("Starting...")

    mixeff <- as.vector(unlist(start, use.names = F))

    family <- vtg.glmm:::get_family(family)

    vtg::log$debug("Using nlm to optimize GLMM...")

    res <- nlm(f = vtg.glmm::concatenate_results, p=mixeff,
               client = client, local_eval = local_eval,
               formula=formula, family = family, nAGQ = nAGQ,
               hessian = TRUE, iterlim = 10000
               check.analyticals = T)

    vtg::log$debug("Collected local deviance...")

    if(!is.language(formula)){

        formula = formula(formula)

    }

    output <- list(
        paste("Generalized linear mixed model fit by minimized deviance",
              sprintf("(Adaptive Gauss-Hermite Quadrature, nAGQ = %d)", nAGQ)),
        deviance = res$minimum,
        fixed_effects = res$estimate[2:length(mixeff)],
        random_effect = res$estimate[1],
        gradient = res$gradient,
        hessian = res$hessian,
        variance_covariance = solve(0.5*res$hessian),
        formula = Reduce(paste, deparse(formula)),
        family = family$family,
        link = family$link,
        nlm_code = res$code,
        iterations = res$iterations,
        nAGQ = nAGQ,
        number_of_groups = vtg::get.option("number_of_groups")
    )

    vtg::log$debug("Finalized...")

    return(output)


}
