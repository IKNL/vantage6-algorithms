#' #' Create GLMM object
#' #'
#' #' fill a GLMM object with output of Federated Learning GLMM
#' #'
#' #' @param obj output of federated GLMM
#' #'
#' #' @param data ...
#' #'
#' #' @return GLMM object
#' #'
#' glmm_wrapper <- function(obj, data=NULL){
#'
#'
#'     # choose.cols <- gsub(pattern = ' ', replacement = '', x = rownames(attr(terms.formula(f), "factors")))
#'     # mc <- match.call()
#'     fe.coef <- obj$fixed_effects
#'     re.intercept <- obj$random_effect
#'     var.covar <- obj$variance_covariance
#'     hessian <- obj$hessian
#'     bar.f <- findbars(as.formula(obj$formula))
#'     dots <- as.vector(x = c(re.intercept, fe.coef))
#'     out <- list()
#'     out$title <- obj[[1]]
#'     # tt <- terms(lme4:::asOneFormula(as.formula(y$formula), data = data))
#'     tt <- terms.formula(lme4:::subbars(formula(obj$formula)), data=data)
#'     name.re <- as.character(bar.f[[1]][[3]])
#'     reTerms <- mkReTrms(bars = bar.f, fr = mf)
#'     if(!is.null(data)){
#'         mf <- model.frame(tt, df)
#'         vn <- sapply(attr(tt, "variables")[-1], deparse)
#'
#'         ## tt <-M_2$terms ????#################################################################
#'
#'         if ((yvar <- attr(tt, "response")) > 0) {
#'             resp <- vn[yvar]
#'             vn <- vn[-yvar]
#'         }
#'
#'         xlvl <- lapply(df[vn], function(x) {
#'             if(is.factor(x)){
#'                 return(levels(x))
#'             } else if (is.character(x)){
#'                 return(levels(as.factor(x)))
#'             } else {
#'                 return(NULL)
#'             }
#'         })
#'         attr(out, "xlevels") <- xlvl[!vapply(xlvl, is.null, NA)]
#'         attr(tt, "dataClasses") <- sapply(df[vn], stats:::.MFclass)
#'     }
#'     names.fe <- vn[-which(vn %in% name.re)]
#'     out$terms <- tt
#'
#'     coef <- numeric(0)
#'
#'
#'     stopifnot(
#'         ((length(fe.coef) & length(re.intercept) >= 1) &
#'           (!is.null(names.fe) & !is.null(name.re))
#'     ))
#'     coef = numeric(0)
#'     for (i in 1:length(dots)){
#'         if (i == 1) {
#'             coef[paste0("Standard Error: ",name.re)] <- dots[[i]]
#'             i = i + 1
#'         }
#'         if (i == 2){
#'             coef[paste0("(Intercept)")] <- dots[[i]]
#'             i = i + 1
#'         }
#'
#'         else {
#'             coef[paste0(names.fe)] <- dots[[i]]
#'         }
#'     }
#'
#'     out$coefficients <- coef
#'     out$rank <- length(coef)
#'     out$reTerms <- reTerms
#'     family <- get_family(obj$family)
#'     formula <- lme4:::subbars(formula(obj$formula))
#'
#'     if (!missing(family)) {
#'         out$family <- if (class(family) == "family") {
#'             family
#'         } else if (class(family) == "function") {
#'             family()
#'         } else if (class(family) == "character") {
#'             get(family)()
#'         } else {
#'             stop(paste("invalid family class:", class(family)))
#'         }
#'
#'     ##### what is qr, line 71 #####
#'
#'         nlm.code <- list(
#'             '1' = paste("relative gradient is close to zero, current iterate
#'                         is probably solution."),
#'             '2' = paste("successive iterates within tolerance, current iterate
#'             is probably solution."),
#'             '3' = paste("last global step failed to locate a point lower than
#'                         estimate. Either estimate is an approximate local
#'                         minimum of the function or steptol is too small."),
#'             '4' = paste("iteration limit exceeded."),
#'             '5' = paste("maximum step size stepmax exceeded five consecutive
#'                         times. Either the function is unbounded below, becomes
#'                         asymptotic to a finite value from above in some
#'                         direction or stepmax is too small.")
#'         )
#'
#'         out$deviance <- obj$deviance
#'         out$iter <- obj$iterations
#'         out$msg <- nlm.code[[obj$nlm_code]]
#'         out$df.null <- obj$number_of_obs - 1
#'         out$df.residual <- obj$number_of_obs - obj$rank
#'         out$call <- call("glmm_FL", formula, family=family)
#'
#'         class(out) <- c("glm", "lm")
#'
#'     } else {
#'
#'         class(out) <- "lm"
#'         out$fitted.values <- predict(out, newdata = dd) ################################### <- dd?
#'         out$residuals <- out$mf[attr(tt, "response")] - out$fitted.values
#'         out$df.resudal <- nrow(data) - out$rank
#'         out$model <- data
#'     }
#'     out
#' }
#'
#'
#'
#' # x <- c("AB.38.2", "GF.40.4", "ABC.34.2")
#' # only_letters <- function(x) { gsub("^([[:alpha:]]*).*$","\\1",x) }
#' # only_letters(x)
#' #
#' #
#' # xxx = strsplit(names(re.intercept), "")
#' # xxx[[1]][1:3]
#'
#' # for(i in seq_along(dots)){
#' #     v <- dots[[i]]
#' #     if(i == 1)){
#' #         coef[paste0(name.re)] <- v[[i]]
#' #     }
#' #     else if (length(fe.coef) != names.fe){
#' #         if (names(fe.coef) == "(Intercept)") {
#' #             coef["(Intercept)"] <- v[[i]]
#' #             }
#' #     else{
#' #         coef[paste0(name.fe)] <- v[[i]]
#' #     }
#' #         }
#' # }
#'
#'
#'
#'
#'
#'
#' #
#' #     fix.eff <- res$coefficients[-1]
#' #
#' #
#' #
#' #     out <- list()
#' #
#' #     title <- paste("Generalized linear", "mixed model fit by",
#' #                    "minimized deviance",
#' #                    sprintf("(Adaptive Gauss-Hermite Quadrature, nAGQ = %d)",
#' #                            res$nAGQ)
#' #                    )
#'
#'
#'
#'
#' # set.seed(101)
#' # ss <- sleepstudy[sample(nrow(sleepstudy), size = round(0.9 * nrow(sleepstudy))), ]
#' # m1 <- lmer(Reaction ~ Days + (1 | Subject) + (0 + Days | Subject), ss)
#' #
#' # summary(m1)
#' # dd <- as.function(m1)
#' # fix.eff
#'
#'
#' ###############################
#' #### Create merMod objects ####
#' ###############################
#' #
#' # fr.1 <- glFormula(formula = f,
#' #                   data = datasets[[1]],
#' #                   family = "poisson",
#' #                   start = list(theta = 0.1, fixef = c(0.1, 0.1)),
#' #                   control = glmerControl(
#' #                       optimizer = "nlminbwrap",
#' #                       optCtrl = list(maxfun = 1)
#' #                   ))
#' #
#' # fr.2 <- glFormula(formula = f,
#' #                   data = datasets[[2]],
#' #                   family = "poisson",
#' #                   start = list(theta = 0.1, fixef = c(0.1, 0.1)),
#' #                   control = glmerControl(
#' #                       optimizer = "nlminbwrap",
#' #                       optCtrl = list(maxfun = 1)
#' #                   ))
#' #
#' #
#' # fr.T <- glFormula(formula = f,
#' #                   data = df,
#' #                   family = "poisson",
#' #                   start = list(theta = 0.1, fixef = c(0.1, 0.1)),
#' #                   control = glmerControl(
#' #                       optimizer = "nlminbwrap",
#' #                       optCtrl = list(maxfun = 1)
#' #                   ))
#' #
#' # model.frame = df[,c("awards", "math", "cid")]
#' # re.T = mkReTrms(findbars(f), model.frame)
#' #
#' # model.frame.1 = datasets[[1]][, c("awards", "math", "cid")] # model.frame(subbars(f), data = model.frame.1)
#' # re.1 = mkReTrms(findbars(f), model.frame.1)
#' #
#' # model.frame.2 = datasets[[2]][, c("awards", "math", "cid")]
#' # re.2 = mkReTrms(findbars(f), model.frame.2)
#' #
#' # fr.T$reTrms$Zt == rbind(fr.1$reTrms$Zt, t(fr.2$reTrms$Zt))
#' #
#' # as.matrix(rbind(fr.1$reTrms$Ztlist, fr.2$reTrms$Ztlist)
#' #
#' # dev.fun <- do.call(mkGlmerDevfun, b.f)
#' #
#' # is.environment(dev.fun)
#' #
#' # opt <- optimizeGlmer(dev.fun, nAGQ)
#' # opt[1:3]
#' # mkMerMod(environment(dev.fun))
#'
#'
#'
