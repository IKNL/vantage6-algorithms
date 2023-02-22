#' RPC call for the second data loop of the federated GLM
#'
#' @param partials
#'
#' @param master a list of parameters used to compute the GLM
#'
#' @return global updated parameters
#'
master_deviance <- function(
    partials,
    family,
    dstar) {

    vtg::log$debug("Starting master deviance.")

    # Get the family required (gaussian, poisson, logistic,...)
    family <- vtg.glm::get_family(family, dstar)

    # Sum up deviance of previous iteration
    dev_old <- Reduce(`+`, lapply(seq_len(length(partials)),
        function(j) partials[[j]]$dev_old))
    # Sum up new deviance
    dev <- Reduce(`+`, lapply(seq_len(length(partials)),
        function(j) partials[[j]]$dev))
    # Sum up null deviance
    dev_null <- Reduce(`+`, lapply(seq_len(length(partials)),
        function(j) partials[[j]]$dev_null))

    return(list(dev_old = dev_old, dev = dev, dev_null = dev_null))
}
