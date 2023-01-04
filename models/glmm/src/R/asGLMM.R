#'
#' Convert federated glmm output to glmm object
#'
#' @export
#'

as.GLMM <- function(result, data=NULL, ...){

    new_env <- new.env(parent = baseenv())

    out <- list()

    f <- if(!is.language(result$formula)) {
        as.formula(result$formula)
    } else {
        result$formula
    }

    setClass(Class = "glmm",
             slots = list(
                 title = "character",
                 formula = "formula",
                 theta = "numeric",
                 beta = "numeric",
                 Data = "numeric",
                 family = "family",
                 frame = "data.frame",
                 X = "matrix",
                 Z = "dgCMatrix",
                 groups = "list",
                 gradient = "numeric",
                 hessian = "matrix",
                 vcov = "matrix",
                 nAGQ = "numeric",
                 call = "call"),
             where = new_env)

    if(!is.null(data)){

        tt <- lme4::glFormula(formula = f, data = data, family = result$family)

        pars <- lme4::mkParsTemplate(formula = f, data=data)

        out <- new(
            "glmm",
            title = result[[1]],
            formula = f,
            Data = c(-0.5*result$deviance, result$deviance),
            theta = result$random_effect,
            beta = result$fixed_effects,
            family = get(result$family, mode = "function")(),
            frame = tt$fr,
            X = tt$X,
            Z = tt$reTrms$Zt,
            groups = tt$reTrms$flist,
            gradient = result$gradient,
            hessian = result$hessian,
            vcov = result$variance_covariance,
            nAGQ = result$nAGQ,
            call = call("glmm_FL", f, family = result$family)
        )

        names(out@beta) <- names(pars$beta)
        names(out@theta) <- names(pars$theta)
        names(out@Data) <- c("loglik", "deviance")

    }

    return(out)
}
