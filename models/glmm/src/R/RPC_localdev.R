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
#' @importFrom numDeriv grad
#' @importFrom numDeriv hessian
#'
#' @export
#'
RPC_localdev <- function(data,
                         formula,
                         start,
                         family,
                         nAGQ){
    # lgr::threshold('debug')
    # log$debug("Initializing parameters...")
    formula <- if(!class(formula) == "formula"){
        as.formula(formula)
    }else{
        formula
    }
    # family <- if(is.null(family)){
    #     get_family(family)
    #
    # }else{
    #     get("gaussian")()
    # }
    mixeff <- as.vector(unlist(start, use.names = T))
    ranef <- mixeff[1:length(findbars(formula))]
    beta <- mixeff[(length(ranef)+1):length(mixeff)]
    ME <- collect_ME(ranef, beta)
    re_names = as.character(lapply(findbars(formula), function(i) i[[3]]))
    groups = sapply(re_names, function(i) unique(data[[i]]))
    number_of_groups <- length(groups)
    if(number_of_groups > 1){
        nAGQ = 1L
    }
    # log$debug("Running Objective Deviance...")
    # suppressWarnings(iter1 <- glmer(formula=formula,
    #                                 data=data,
    #                                 family=family,
    #                                 nAGQ=nAGQ,
    #                                 control=glmerControl(
    #                                     optimizer="nlminbwrap",
    #                                     optCtrl=list(maxfun=1)
    #                                     ),
    #                                 start=list(fixef=beta,
    #                                              theta=ranef)))

    ## I want to run normal GLM
    single_iteration <- function(formula, data, family, nAGQ, params){
        fn <- function(params){
            suppressWarnings(glmer(formula = formula, data = data,
                                   family = family,nAGQ = nAGQ,
                                   control = glmerControl(
                                       optimizer = "nlminbwrap",
                                       optCtrl = list(maxfun = 1)
                                   ), start = list(fixef = params[["beta"]],
                                                   theta = params[["ranef"]]))
                             )}
        execute <- fn(params)
        out <- execute@devcomp$cmp["dev"]
        attr(out, "gradient") <- numDeriv::grad(
            func = function(x) {
                as.numeric(fn(list(beta = x[(number_of_groups+1):length(x)],
                                   ranef = x[1:number_of_groups])
                              )@devcomp$cmp["dev"])
            },x = unlist(params, use.names = F))
        attr(out, "hessian") <- numDeriv::hessian(
            func = function(x) {
                as.numeric(fn(list(beta = x[(number_of_groups+1):length(x)],
                                   ranef = x[1:number_of_groups])
                )@devcomp$cmp["dev"])
            },x = unlist(params, use.names = F))
        attr(out, "number_of_groups") <- number_of_groups
        intercept <- lapply(1:number_of_groups, function(i){
            lme4::ranef(execute)[[re_names[i]]]}
        )
        names(intercept) <- names(groups)
        attr(out, "intercepts") <- intercept
        attr(out, "conditional_mode_spherical_ranef") <- lme4::getME(execute,
                                                                     "u")
        attr(out, "condtional_mode_ranef") <- as.numeric(lme4::getME(execute,
                                                                     "b"))
        attr(out, "ME") <- ME
        attr(out, "nAGQ") <- nAGQ
        return(out)
    }
    return(single_iteration(formula, data, family, nAGQ, start))
    # groups <- unique(data[[as.character(lme4::findbars(f)[[1]][[3]])]])

    # iter1 <- single_iteration(
    #             formula,
    #             data,
    #             family,
    #             nAGQ,
    #             beta,
    #             ranef
    #         )
    # res <- as.numeric(iter1@devcomp$cmp["dev"])
    # attr(res, "gradient") <- iter1@optinfo$derivs$gradient
    # grad_hess <- client$call("grad_hes", fn=single_iteration, formula=formula,
    #                          data=data, family=family, nAGQ=nAGQ, beta=beta,
    #                          ranef=ranef)

    # attr(res, "gradient") <- function(formula, data, family, nAGQ, beta, ranef){
    #     numDeriv::grad(single_iteration(formula,data,family,nAGQ,beta,ranef))@devcomp$cmp["dev"]
    # }
    # attr(res, "hessian") <- grad_hess$hessian
    # attr(res, "hessian") <- iter1@optinfo$derivs$Hessian


    # attr(res, "number_of_groups") <- number_of_groups
    #
    # # intercept <- lme4::ranef(iter1)[[1]][[1]]
    # intercept <- lapply(1:number_of_groups, function(i){
    #     ranef(iter1)[[re_names[i]]]}
    #     )
    #
    # names(intercept) <- names(groups)
    #
    # attr(res, "intercepts") <- intercept
    #
    # attr(res, "conditional_mode_spherical_ranef") <- getME(iter1, "u")
    #
    # attr(res, "condtional_mode_ranef") <- as.numeric(getME(iter1,"b"))
    #
    # attr(res, "ME") <- ME
    #
    # attr(res, "nAGQ") <- nAGQ
    #
    # return(res)

}

