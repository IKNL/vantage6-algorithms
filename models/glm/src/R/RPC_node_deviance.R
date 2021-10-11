#' RPC call for the second data loop of the federated GLM
#'
#' @param data dataframe containing the data
#' @param weights an optional vector of ‘prior weights’ to be used in the
#' fitting process. Should be NULL or a numeric vector.
#' @param master a list of parameters used to compute the GLM
#'
#' @return GLM partials
#'
RPC_node_deviance <- function(data, weights = NULL, master) {

    vtg::log$debug("Starting node deviance.")

    # Specify data types for the columns in the data
    if(!is.null(master$types)){
        data = format_data(data,master$types)
    }

    # The function update the betas
    formula <- master$formula
    family <- master$family
    dstar <- master$dstar

    # The function calculate the residual deviance with updated betas for the
    # single node extract y variable names
    y <- eval(formula[[2]], envir = data)
    # Extract X variables
    X <- model.matrix(formula,data = data)
    # Extract the offset
    offset=model.offset(model.frame(formula, data = data))

    # Functions of the family required (gaussian, poisson, logistic,...)
    if(family=='rs.poi') {
        if(is.null(dstar)) {
            vtg::log$debug("expected count required for relative survival")
            return()
        }
        family <- poisson()
        family$family <- "rs.poi"
        family$link <- "glm relative survival model with Poisson error"
        family$linkfun <- function(mu) log(mu - dstar)
        family$linkinv <- function(eta) dstar + exp(eta)
        dstar=eval(as.name(dstar), data)
    } else {
        if (is.character(family))
            family <- get(family, mode = "function", envir = parent.frame())
        if (is.function(family))
            family <- family()
        if (is.null(family$family))
            stop(glue::glue("family '{family}' not recognized"))
    }

    if (is.null(weights)) weights <- rep.int(1, nrow(X))
    if (is.null(offset)) offset <- rep.int(0, nrow(X))

    if (master$iter == 1) {
        vtg::log$debug("First iteration. Initializing variables.")
        etastart = NULL

        # Initializes n and fitted values mustart
        if (family$family=="rs.poi") {
            mustart= pmax(y,dstar) + 0.1
        } else {
            # (!) needed by the initialize expression below
            nobs = nrow(X)
            nvars = ncol(X)
            # Initializes n and fitted values mustart
            eval(family$initialize)
        }

        # Initialize eta
        eta = family$linkfun(mustart) + offset
        mu_old = family$linkinv(eta)
        dev_old = 0

    } else {
        mu_old <- family$linkinv(X %*% master$coef[,ncol(master$coef)-1])
        dev_old <- sum(family$dev.resids(y, mu_old,weights))
    }

    vtg::log$debug("Updating the variables for node deviance.")
    eta <- X %*% master$coef[,ncol(master$coef)] + offset #calcaute updated eta
    mu <- family$linkinv(eta - offset)
    dev <- sum(family$dev.resids(y, mu, weights)) #calculate new deviance
    dev.null <- sum(family$dev.resids(y, master$wtdmu, weights))

    # Return
    list(dev_old = dev_old, dev = dev, dev.null = dev.null)
}
