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
#' @importFrom lme4 findbars
#' @importFrom lme4 glmer
#' @importFrom lme4 getME
#' @importFrom lgr threshold
#' @importFrom vtg log
#'
#' @export
#'
RPC_localdev <- function(data,
                         formula,
                         params,
                         family,
                         nAGQ){
    formula <- if(!class(formula) == "formula"){
        as.formula(formula)
    }else{
        formula
    }
    re_names <- as.character(sapply(lme4::findbars(formula), function(i) i[[3]]
    ))
    if(length(re_names) > 1){
        error <- "Cannot handle more than one scalar factor re."
        return(vtg::error_format(error))
    }
    mixeff <- as.vector(unlist(params))
    ranef <- mixeff[1:length(re_names)]
    beta <- mixeff[(length(ranef)+1):length(mixeff)]
    ME <- collect_ME(ranef, beta)
    groups = sapply(re_names, function(i) unique(data[[i]]))
    number_of_groups <- length(groups)

    single_iteration <- function(formula, data, family, nAGQ, params){
        fn <- function(params){
            suppressWarnings(lme4::glmer(formula = formula, data = data,
                                         family = family,nAGQ = nAGQ,
                                         control = glmerControl(
                                         optimizer = "nlminbwrap",
                                         optCtrl = list(maxfun = 1)
                                         ), start = list(fixef = beta,
                                                         theta = ranef))
            )
            }
        execute <- fn(params)
        out <- execute@devcomp$cmp["dev"]
        attr(out, "hessian") <- execute@optinfo$derivs$Hessian
        attr(out, "gradient") <- execute@optinfo$derivs$gradient
        attr(out, "number_of_groups") <- number_of_groups
        attr(out, "ME") <- ME
        attr(out, "nAGQ") <- nAGQ
        return(out)
    }
    return(single_iteration(formula, data, family, nAGQ, params))
}
