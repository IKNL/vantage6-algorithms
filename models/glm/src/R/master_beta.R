#' Combine the results from the first RPC call and update the betas
#' accordingly
#'
#' Computes: X^T W X and X^T W z from the partials. Then computes the
#' updated betas by multiplying these.
#'
#' @param partials result of rpc_node_beta, partial results from the
#'   individual nodes
#' @param family family type
#' @param dstar name of the dstar sensor column (e.g. expected deaths).
#'  Only applicable when using the glm relative survival model with
#'  Poisson regression)
#'
#' @return global updated parameters
#'
master_beta <- function(partials, family, dstar) {

    vtg::log$debug("Initializing master Beta...")

    # Get the family (Gaussian, Poisson, logistic,...)
    family <- vtg.glm::get_family(family, dstar)

    g <- partials

    vtg::log$debug("Merging node calculation to update new Betas.")
    s <- seq_len(length(g))
    # Total sum of weights
    allwt <- Reduce(`+`, lapply(s, function(j) g[[j]]$wt2))
    # Global weighted mu
    wtdmu <- Reduce(`+`, lapply(s, function(j) g[[j]]$wt1 / allwt))
    # Sum up components of the matrix to be inverted calculated in each node
    a <- Reduce(`+`, lapply(s, function(j) g[[j]]$v1))
    # Sum up components of the matrix to be inverted calculated in each node
    b <- Reduce(`+`, lapply(s, function(j) g[[j]]$v2))
    # Sum up components dispersion matrix
    phi <- Reduce(`+`, lapply(s, function(j) g[[j]]$dispersion))
    # Total number of observation
    nobs <- Reduce(`+`, lapply(s, function(j) g[[j]]$nobs))
    # Number of variables
    nvars <- nrow(g[[1]]$v1)

    if (family$family %in% c("poisson", "binomial", "rs.poi")) {
        disp <- 1
        est_disp <- FALSE
    } else {
        disp <- phi / (nobs - nvars)
        est_disp <- T
    }

    vtg::log$debug("Updating the Betas.")
    # Calculate the new betas
    fb <- solve(a, b, tol = 2 * .Machine$double.eps)

    # Calculate the Standard error of coefficients
    se <- sqrt(diag(solve(a) * disp))

    # update the parameters
    output <- list(
        coef = fb,
        se = se,
        disp = disp,
        est_disp = est_disp,
        nobs = nobs,
        nvars = nvars,
        wtdmu = wtdmu
    )

    # Return
    return(output)
}