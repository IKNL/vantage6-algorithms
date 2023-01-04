#' RPC call for single iteration of nAGQ procedure to find minimized Deviance.
#'
#' Executes a single iteration of the glmer Function from the lme4 package to
#' obtain a deviance, gradient and hessian. For further details on the glmer
#' function please see `help(lme4::glmer)`.
#'
#' @param data Dataframe containing the data which is automatically supplied by
#' the node.
#'
#' @param formula A two-sided linear formula object describing both the fixed
#' effects and random effect parts of the model. The response parameter must be
#' on the left hand side of a '~' operator and the independent variables that
#' follow must be separated with a '+' operator. The random effect term must
#' be distinguished by a vertical bar '|'.
#'
#' @param start List of starting values for the Random Effect Term and the
#' Fixed Effect Term(s). Note that one should invoke the list in the following
#' manner: start = list(theta = x, fixef = y) where `x` is a single value, and
#' `y` can be a vector of starting values depending on how many fixed effects
#' are included in the model.
#'
#' @param len.theta Integer Scalar- since the current implementation of the
#' Adaptive Gauss Hermite Quadrature Scheme used in glmer only allows for one
#' Random Effect Intercept Term, this has value has to be set to 1. If not then
#' no optimization will proceed.
#'
#' @param family Family type, if non is supplied then Gaussian Family is used.
#'
#' @param nAGQ Integer Scalar of the number of points per axis for evaluating
#' the Adaptive Gauss Hermite Quadrature approximation to the log-likelihood.
#' The default number we take is 10, but this can go up to 25 or as few as 1.
#' The latter will simply be the Laplace Approximation of the Deviance.
#'
#' @return A Single Iteration of the nAGQ approximation of the minimized
#' Deviance. Along with this, the gradient and hessian are given as attributes.
#'
#' @export
#'
RPC_localdev <- function(data,
                         formula,
                         start,
                         family,
                         nAGQ){

    library("lme4")
    lgr::threshold('debug')
    vtg::log$debug("Initializing parameters...")
    formula <- as.formula(formula)
    family <- get_family(family)
    len.theta <- 1
    mixeff <- as.vector(unlist(start, use.names = F))
    beta <- mixeff[(len.theta+1):length(mixeff)]
    ranef <- mixeff[1:len.theta]

    if(is.null(nAGQ)){

        nAGQ <- 20

    }

    if(is.null(family)){

        family <- get_family("gaussian")

    }

    vtg::log$debug("Running Objective Deviance...")
    suppressWarnings(iter1 <- lme4::glmer(formula = formula,
                                          data = data,
                                          family = family,
                                          nAGQ = nAGQ,
                                          control = glmerControl(
                                              optimizer = "nlminbwrap",
                                              optCtrl = list(maxfun=1,
                                                        xtol_abs=1e-8,
                                                        ftol_abs=1e-8)
                                    ),
                                         start = list(fixef = beta,
                                                      theta = ranef)
                                    )
                     )
    number_of_groups <- length(unique(data[[as.character(lme4::findbars(f)[[1]][[3]])]]))
    res <- as.numeric(iter1@devcomp$cmp["dev"])
    attr(res, "gradient") <- iter1@optinfo$derivs$gradient
    attr(res, "hessian") <- iter1@optinfo$derivs$Hessian
    attr(res, "family") <- iter1@resp$family
    attr(res, "number_of_groups") <- number_of_groups

    return(res)

}

