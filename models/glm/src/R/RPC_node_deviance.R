#' RPC call for the second data loop of the federated GLM
#'
#' @param data dataframe containing the data
#' @param weights an optional vector of ‘prior weights’ to be used in the
#' fitting process. Should be NULL or a numeric vector.
#' @param master a list of parameters used to compute the GLM
#'
#' @return GLM partials
#'
RPC_node_deviance <- function( #nolint
    data,
    formula,
    family,
    first_iteration,
    dstar,
    coeff,
    coeff_old,
    wtdmu,
    types=NULL,
    weights = NULL) {

    vtg::log$debug("Starting node deviance.")

    # Specify data types for the columns in the data
    if (!is.null(types)) {
        data <- vtg.glm::assign_types(data, types)
    }

    # The function calculate the residual deviance with updated betas for the
    # single node extract y variable names
    y <- eval(formula[[2]], envir = data)
    # Extract X variables
    X <- model.matrix(formula, data = data) #nolint
    # Extract the offset
    offset <- model.offset(model.frame(formula, data = data))

    # Get the family required (gaussian, poisson, logistic,...)
    dstar <- if (family == "rs.poi") eval(as.name(dstar), data) else dstar
    family <- vtg.glm::get_family(family, dstar)

    weights <- if (is.null(weights)) rep.int(1, nrow(X)) else weights
    offset <- if (is.null(offset)) rep.int(0, nrow(X)) else offset

    if (first_iteration) {
        vtg::log$debug("First iteration. Initializing variables.")

        # Initializes n and fitted values mustart
        if (family$family == "rs.poi") {
            mustart <- pmax(y, dstar) + 0.1
        } else {
            # (!) needed by the initialize expression below
            etastart <- NULL #nolint
            nobs <- nrow(X) #nolint
            nvars <- ncol(X) #nolint
            # Initializes n and fitted values mustart
            eval(family$initialize)
        }

        # Initialize eta
        eta <- family$linkfun(mustart) + offset
        mu_old <- family$linkinv(eta)
        dev_old <- 0

    } else {
        mu_old <- family$linkinv(X %*% coeff_old)
        dev_old <- sum(family$dev.resids(y, mu_old, weights))
    }

    vtg::log$debug("Updating the variables for node deviance.")
    eta <- X %*% coeff + offset #calcaute updated eta
    mu <- family$linkinv(eta - offset)
    dev <- sum(family$dev.resids(y, mu, weights)) #calculate new deviance
    dev_null <- sum(family$dev.resids(y, wtdmu, weights))

    output <- list(dev_old = dev_old, dev = dev, dev_null = dev_null)
    print(output)
    return(output)
}
