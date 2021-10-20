#' RPC call for the second data loop of the federated GLM
#'
#' @param nodes list of results from the individual nodes
#' @param master a list of parameters used to compute the GLM
#'
#' @return global updated parameters
#'
master_deviance <- function(nodes = NULL, master) {

    vtg::log$debug("Initializing master deviance...")
    tol <- master$tol
    maxit <- master$maxit
    formula <- master$formula
    family <- master$family

    if (family=='rs.poi') {
        family <- poisson()
        family$family <- "rs.poi"
        family$link <- "glm relative survival model with Poisson error"
        family$linkfun <- function(mu) log(mu - dstar)
        family$linkinv <- function(eta) dstar + exp(eta)
    } else {
        if (is.character(family))
            family <- get(family, mode = "function", envir = parent.frame())
        if (is.function(family))
            family <- family()
        if (is.null(family$family))
            stop(glue::glue("familty '{family}' not recognized"))
    }

    x <- nodes
    # Sum up deviance of previous iteration
    dev_old <- Reduce(`+`, lapply(1:length(x), function(j) x[[j]]$dev_old))
    # Sum up new deviance
    dev <- Reduce(`+`, lapply(1:length(x), function(j) x[[j]]$dev))
    # Sum up null deviance
    dev.null <- Reduce(`+`, lapply(1:length(x), function(j) x[[j]]$dev.null))
    # Evaluate if algorithm  converge
    convergence <- (abs(dev - dev_old) / (0.1 + abs(dev)) < tol)

    if(convergence==FALSE & master$iter<maxit) {
        vtg::log$debug("Model hasn't converged. Max iteration not reached.")
        master$converged = convergence
        master$iter = master$iter+1
        return(master)
    } else {
        zvalue <- master$coef[,ncol(master$coef)]/master$se
        if (master$est.disp) {
            pvalue <- 2 * pt(-abs(zvalue), master$nobs-master$nvars)
        } else {
            pvalue <- 2 * pnorm(-abs(zvalue))
        }
        vtg::log$debug("Model converged. Collecting output.")
        master <- list(converged=TRUE,
                       coefficients=as.pairlist(master$coef[,ncol(master$coef)]),
                       Std.Error=as.pairlist(master$se),
                       pvalue=as.pairlist(pvalue),
                       zvalue=as.pairlist(zvalue),
                       dispersion=master$disp,
                       est.disp=master$est.disp,
                       formula=master$formula,
                       family=family,
                       iter=master$iter,
                       deviance=dev,
                       null.deviance=dev.null,
                       nobs=master$nobs,
                       nvars=master$nvars)
        # Return
        master
    }
}