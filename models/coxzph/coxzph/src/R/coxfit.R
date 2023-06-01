#' Server side, collects the coxfit run by vtg.coxph
#'
#' This only looks at the relevant output from vtg.coxph, this means that it
#' looks at the coefficients (Beta) and the variance-covariance matrix
#' (Betavar)
#'
#' @return return list with beta coefficients and betavar
#'
#' @export
#'
coxfit <- function(fit){
    vtg::log$debug("Initializing the coxfit...")
    beta <- as.matrix(fit$coef)
    betavar <- fit$var
    row.names(beta) <- row.names(betavar)

    list(
        beta=beta,betavar=betavar)
}
