#'
#' Convert federated glmm output glmm class
#'
#' @export
#'
as.GLMM <- function(result, ..., data=NULL){

    out <- list("Title" = result[[1]])

    dots <- as.list(c(result$random_effect, result$fixed_effects))

    f <- if(!is.language(result$formula)) {

        as.formula(result$formula)

    } else {

        result$formula

    }

    if(is.null(data)){
        stop("Need data to create glmm object...")
    }

    glF <- lme4::glFormula(formula=f, data=data, family=result$family)

    pars <- lme4::mkParsTemplate(formula=f, data=data)

    if(!is.null(data)){

        mf <- glF$fr
        tt <- attributes(mf)$terms
        vn <- sapply(attr(tt, "variables")[-1], deparse)
        if((yvar <- attr(tt, "response"))>0)
            vn <- vn[-yvar]
            xlvl <- lapply(data[vn], function(x) if (is.factor(x))
            levels(x)
            else if (is.character(x))
                levels(as.factor(x))
            else
                NULL)
        attr(tt, "predvars.fixed") <- c(attr(tt, "predvars.fixed"), xlvl[!vapply(xlvl,is.null,NA)])
        attr(tt, "predvars.random") <- c(attr(tt, "predvars.random"), attributes(glF$reTrms$flist[[1]]))
    }

    out$model.frame <- glF$fr

    out$deviance <- result$deviance

    out$logLik <- -0.5 * result$deviance

    out$terms <- tt
    names(dots) <- paste0(c(as.character(names(pars$theta)), as.character(names(pars$beta))))
    coef <- as.numeric(dots)
    names(coef) <- names(dots)

    out$coefficients <- coef

    out$derivs <- list(
        "Gradient" = result$gradient,
        "Hessian" = result$hessian
    )

    out$var.covar <- result$variance_covariance

    out$iter <- result$iterations

    out$aic <- 1

    family <- result$family

    if(!missing(family)){
        out$family <- if(class(family) == "family"){
            family
        }else if(class(family) == "function"){
            family()
        }else if(class(family) == "character"){
            get(family)()
        }else{
            stop(paste("invalid family class:", class(family)))
        }
    }

    out$call <- call("glmm_FL", f, family = result$family)

    class(out) <- c("glmm")

    return(out)
}
