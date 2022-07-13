#' RPC call for the first data loop of the federated GLM
#'
#' @param data dataframe containing the data, this is automatically
#'   supplied by the node
#' @param formula an object of class formula (or one that can be coerced
#'   to that class: a symbolic description of the model to be fitted.
#'   E.g.: dependant_variable ~ explanatory_variable(i) + ...
#' @param family family type, Gaussian is used by default
#' @param first_iteration boolean to indicate if this is the first
#'  iteration
#' @param coeff beta coefficients from previous iteration
#' @param dstar name of the dstar sensor column (e.g. expected deaths).
#'  Only applicable when using the glm relative survival model with
#'  Poisson regression)
#' @param types types of the columns that are used in the formula
#' @param weights an optional vector of ‘prior weights’ to be used in the
#'   fitting process. Should be NULL or a numeric vector
#'
#' @return GLM partials
#'
RPC_node_beta <- function( #nolint
    data,
    formula,
    family,
    first_iteration,
    coeff,
    dstar = NULL,
    types = NULL,
    weights = NULL) {

    vtg::log$debug("Initializing node beta...")

    # Specify data types for the columns in the data
    if (!is.null(types)) {
      data <- vtg.glm::assign_types(data, types)
    }

    # Extract y and X variables name from formula
    y <- eval(formula[[2]], envir = data)
    X <- model.matrix(formula, data = data) #nolint

    # Extract the offset from formula (if exists)
    offset <- model.offset(model.frame(formula, data = data))

    # Get the family required (Gaussian, Poisson, logistic,...)
    dstar <- if (family == "rs.poi") eval(as.name(dstar), data) else dstar
    family <- vtg.glm::get_family(family, dstar)

    weights <- if (is.null(weights)) (rep.int(1, nrow(X))) else weights
    offset <- if (is.null(offset)) rep.int(0, nrow(X)) else offset

    # (!) `nobs` and `nvars` needed by the initialize expression below
    nobs <- nrow(X)
    nvars <- ncol(X)

    if (first_iteration) {
        vtg::log$debug("First iteration. Initializing variables.")

        # Initializes n and fitted values mustart
        if (family$family == "rs.poi") {
            mustart <- pmax(y, dstar) + 0.1
        } else {
            # we need to set `etastart` which is used when evaluating
            # the expression from `family$initialize`
            etastart = NULL # nolint
            eval(family$initialize)
        }
        # Initialize eta
        eta <- family$linkfun(mustart)
    } else {
        eta <- (X %*% coeff) + offset
    }

    vtg::log$debug("Calculating the Betas.")
    mu <-  family$linkinv(eta)
    varg <- family$variance(mu)
    gprime <- family$mu.eta(eta)

    # Calculate z
    z <- (eta - offset) + (y - mu) / gprime
    # Update the weights
    W <- weights * as.vector(gprime^2 / varg) #nolint
    # Calculate the dispersion matrix
    dispersion <- sum(W * ((y - mu) / family$mu.eta(eta))^2)

    output <- list(
        v1 = crossprod(X, W * X),
        v2 = crossprod(X, W * z),
        dispersion = dispersion,
        nobs = nobs,
        nvars = nvars,
        wt1 = sum(weights * y),
        wt2 = sum(weights)
    )

    return(output)
}
