#' RPC call for the second data loop of the federated GLM
#'
#' @param nodes list of results from the individual nodes
#' @param master a list of parameters used to compute the GLM
#'
#' @return global updated parameters
#'
master_beta <- function(nodes = NULL, master = NULL) {

    vtg::log$debug("Initializing master Beta...")
    vtg::log$debug(glue::glue("dstart={master$dstar}"))

    formula <- master$formula
    family <- master$family

    if (family=='rs.poi') {
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
        if (is.null(family$family))
            stop(glue::glue("family '{family}' not recognized"))
    }

    g <- nodes

    vtg::log$debug(g)
    vtg::log$debug("Merging node calculation to update new Betas.")
    # Total sum of weights
    allwt <- Reduce(`+`, lapply(1:length(g), function(j) g[[j]]$wt2))
    # Global weighted mu
    wtdmu <- Reduce(`+`, lapply(1:length(g), function(j) g[[j]]$wt1/allwt))
    # Sum up components of the matrix to be inverted calculated in each node
    a <- Reduce(`+`, lapply(1:length(g), function(j) g[[j]]$v1))
    # Sum up components of the matrix to be inverted calculated in each node
    b <- Reduce(`+`, lapply(1:length(g), function(j) g[[j]]$v2))
    # Sum up components dispersion matrix
    phi <- Reduce(`+`, lapply(1:length(g), function(j) g[[j]]$dispersion))
    # Total number of observation
    nobs <- Reduce(`+`, lapply(1:length(g), function(j) g[[j]]$nobs))
    # Number of variables
    nvars <- nrow(g[[1]]$v1)

    if (is.null(master)) {
        beta <- rep(1, nvars)
    } else {
        beta <- master$coef
    }
    if (family$family %in% c('poisson','binomial','rs.poi')) {
        disp <- 1
        est.disp <- FALSE
    } else {
        disp <- phi / (nobs - nvars)
        est.disp <- T
    }

    vtg::log$debug("Updating the Betas.")
    # Calculate the new betas
    fb <- solve(a, b, tol = 2 * .Machine$double.eps)
    # Calculate the Standard error of coefficients
    se <- sqrt(diag(solve(a) * disp))

    # update the parameters
    master$coef <- cbind(master$coef, fb)
    master$se <- se
    master$disp <- disp
    master$est.disp <- est.disp
    master$nobs <- nobs
    master$nvars <- nvars
    master$wtdmu <- wtdmu

    # Return
    master
}