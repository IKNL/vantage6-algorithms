master_deviance <- function(..., nodes = NULL, master) {
    #receive as many object as many are the nodes involved in the analysis (...)
    #the function evaluate if the algorithm converge
    #the function update the betas
    vtg::log$debug("Starting master deviance.")
    tol <- master$tol
    maxit <- master$maxit
    formula <- master$formula
    family <- master$family
    if(family=='rs.poi'){
        family <- poisson()
        family$family <- "rs.poi"
        family$link <- "glm relative survival model with Poisson error"
        family$linkfun <- function(mu) log(mu - dstar)
        family$linkinv <- function(eta) dstar + exp(eta)
    }else{
        if (is.character(family))
            family <- get(family, mode = "function", envir = parent.frame())
        if (is.function(family))
            family <- family()
        if (is.null(family$family)) {
            print(family)
            stop("'family' not recognized")
        }
    }
    if (is.null(nodes)) {
        x <- list(...)  #place the dots into a list
    }else {
        x <- nodes
    }
    dev_old <- Reduce(`+`, lapply(1:length(x), function(j) x[[j]]$dev_old)) #sum up deviance of previous iteration
    dev <- Reduce(`+`, lapply(1:length(x), function(j) x[[j]]$dev)) #sum up new deviance
    dev.null <- Reduce(`+`, lapply(1:length(x), function(j) x[[j]]$dev.null)) #sum up null deviance
    convergence <- (abs(dev - dev_old) / (0.1 + abs(dev)) < tol) #evaluate if algorithm  converge
    if(convergence==FALSE & master$iter<maxit) {
        vtg::log$debug("Model hasn't converged. Max iteration not reached.")
        master$converged = convergence
        master$iter = master$iter+1
        #saveRDS(master,file = paste0("master.Rds"))
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
                       coefficients=master$coef[,ncol(master$coef)],
                       Std.Error=master$se,
                       pvalue=pvalue,
                       zvalue=zvalue,
                       dispersion=master$disp,
                       est.disp=master$est.disp,
                       formula=master$formula,
                       family=family,
                       iter=master$iter,
                       deviance=dev,
                       null.deviance=dev.null,
                       nobs=master$nobs,
                       nvars=master$nvars)
        #saveRDS(master,file = paste0("master.Rds"))
        return(master)
    }
    #return a list of output only if the algorithm converge
}