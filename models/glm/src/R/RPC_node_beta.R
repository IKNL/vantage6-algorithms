#' RPC call for the first data loop of the federated GLM
#'
#' @param data dataframe containing the data
#' @param weights an optional vector of ‘prior weights’ to be used in the
#' fitting process. Should be NULL or a numeric vector.
#' @param master a list of parameters used to compute the GLM
#'
#' @return GLM partials
#'
RPC_node_beta <- function(data, weights = NULL, master = NULL) {

    vtg::log$debug("Initializing node beta...")

    # Specify data types for the columns in the data
    if(!is.null(master$types)){
      data <- format_data(data,master$types)
    }

    formula <- master$formula
    family <- master$family
    dstar <- master$dstar

    # Extract y and X varibales name from formula
    y <- eval(formula[[2]], envir = data)
    # Create a model matrix
    X <- model.matrix(formula, data = data)
    # Extract the offset from formula (if exists)
    offset <- model.offset(model.frame(formula, data = data))

    # Functions of the family required (gaussian, poisson, logistic,...)
    if (is.character(family)){
        if(family=='rs.poi'){
            if(is.null(dstar)){
                vtg::log$debug("expected count required for relative survival")
                return()
            }
            family <- poisson()
            family$family <- "rs.poi"
            family$link <- "glm relative survival model with Poisson error"
            family$linkfun <- function(mu) log(mu - dstar)
            family$linkinv <- function(eta) dstar + exp(eta)
            dstar=eval(as.name(dstar),data)
        } else {
            family <- get(family, mode = "function", envir = parent.frame())
        }
    }
    if (is.function(family))
        family <- family()
    if (is.null(family$family))
        stop(glue::glue("family '{family}' not recognized"))

    if (is.null(weights)) weights <- rep.int(1, nrow(X))
    if (is.null(offset)) offset <- rep.int(0, nrow(X))

    # (!) `nobs` and `nvars` needed by the initialize expression below
    nobs <- nrow(X)
    nvars <- ncol(X)

    if (master$iter==1) {
        vtg::log$debug("First iteration. Initializing variables.")
        etastart = NULL

        # Initializes n and fitted values mustart
        if(family$family=="rs.poi") {
            mustart= pmax(y,dstar) + 0.1
        } else {
            eval(family$initialize)
        }
        # Initialize eta
        eta = family$linkfun(mustart)
    } else {
        eta = (X %*% master$coef[,ncol(master$coef)]) + offset
    }

    vtg::log$debug("Calculating the Betas.")
    mu <-  family$linkinv(eta)
    varg <- family$variance(mu)
    gprime <- family$mu.eta(eta)

    # Calculate z
    z <- (eta - offset) + (y - mu) / gprime
    # Update the weights
    W <- weights * as.vector(gprime^2 / varg)
    # Calculate the dispersion matrix
    dispersion <- sum(W *((y - mu) / family$mu.eta(eta))^2)

    output <- list(v1 = crossprod(X, W*X), v2 = crossprod(X, W*z),
                   dispersion = dispersion, nobs = nobs, nvars = nvars,
                   wt1 = sum(weights * y), wt2 = sum(weights))

    return(output)
}
