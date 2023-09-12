#' Run the distributed CoxPH algorithm.
#'
#' Params:
#'   client: ptmclient::Client instance.
#'   input_data: input_data containing
#'      expl_vars: list of explanatory variables (covariates) to use
#'      time_col: name of the column that contains the event/censor times
#'      censor_col: name of the column that explains whether an event occurred
#'                  or the patient was censored
#'
#' Return:
#'   RDS with beta, p-value and confidence interval for each explanatory
#'   variable.
dcoxph <- function(client, expl_vars, time_col, censor_col) {

    MAX_COMPLEXITY = 250000
    USE_VERBOSE_OUTPUT = getOption('vtg.verbose_output', F)

    image.name <- "harbor2.vantage6.ai/algorithms/vtg.coxph:harukas"

    client$set.task.image(
        image.name,
        task.name="CoxPH"
    )

    # Run in a MASTER container
    if (client$use.master.container) {
        vtg::log$debug("Running `dcoxph` in master container using image
                        '{image.name}'")
        result <- client$call("dcoxph", expl_vars, time_col, censor_col)
        return(result)
    }

    # Run in a REGULAR container
    m <- length(expl_vars)

    # Ask all nodes to return their unique event times with counts
    vtg::log$debug("Getting unique event times and counts")
    results <- client$call("get_unique_event_times_and_counts", time_col,
                           censor_col)

    Ds <- lapply(results, as.data.frame)

    D_all <- compute.combined.ties(Ds)
    unique_event_times <- as.numeric(names(D_all))

    complexity <- length(unique_event_times) * length(expl_vars)^2
    vtg::log$debug("********************************************")
    vtg::log$debug(c("Complexity:", complexity))
    vtg::log$debug("********************************************")

    if (complexity > MAX_COMPLEXITY) {
        stop("*** This computation will be too heavy on the nodes! Aborting!
              ***")
    }

    # Ask all nodes to compute the summed Z statistic
    vtg::log$debug("Getting the summed Z statistic")
    summed_zs <- client$call("compute_summed_z", expl_vars, time_col,
                             censor_col)

    # z_hat: vector of same length m
    # Need to jump through a few hoops because apply simplifies a matrix
    # with one row to a numeric (vector) :@
    # z_hat <- list.to.matrix(summed_zs)
    # z_hat <- apply(z_hat, 2, as.numeric)
    # z_hat <- matrix(z_hat, ncol=m, dimnames=list(NULL, expl_vars))
    # z_hat <- colSums(z_hat)
    z_hat <- Reduce(`+`, summed_zs)

    # Initialize the betas to 0 and start iterating
    vtg::log$debug("Starting iterations ...")
    beta <- beta_old <- rep(0, m)
    delta <- 0

    i = 1
    while (i <= 30) {
        vtg::log$debug(sprintf("Executing iteration %i", i))
        if (USE_VERBOSE_OUTPUT) {
            writeln("Beta's:")
            print(beta)
            writeln()

            writeln("delta: ")
            print(delta)
            writeln()
        }

        aggregates <- client$call("perform_iteration", expl_vars, time_col,
                                  censor_col, beta, unique_event_times)

        # Compute the primary and secondary derivatives
        derivatives <- compute.derivatives(z_hat, D_all, aggregates)
        # print(derivatives)

        # Update the betas
        beta_old <- beta
        beta <- beta_old - (solve(derivatives$secondary) %*%
                                derivatives$primary)

        delta <- abs(sum(beta - beta_old))

        if (is.na(delta)) {
            writeln("Delta as turned into a NaN???")
            writeln(beta_old)
            writeln(beta)
            writeln(delta)
            break
        }

        if (delta <= 10^-8) {
            vtg::log$debug("Betas have settled! Finished iterating!")
            break
        }

        # Again!!?
        i <- i + 1
    }

    # Computing the standard errors
    SErrors <- NULL
    fisher <- solve(-derivatives$secondary)

    # Standard errors are the squared root of the diagonal
    for(k in 1:dim(fisher)[1]){
        se_k <- sqrt(fisher[k,k])
        SErrors <- c(SErrors, se_k)
    }

    # Calculating P and Z values
    # zvalues <- (exp(beta)-1)/SErrors

    # Now calculating the z-values the same way `survival::coxph()` does it.
    zvalues <- beta/SErrors
    pvalues <- 2*pnorm(-abs(zvalues))
    pvalues <- format.pval(pvalues, digits = 1)

    # 95%CI = beta +- 1.96 * SE
    results <- data.frame("coef"=round(beta,5), "exp(coef)"=round(exp(beta), 5)
                          , "SE"=round(SErrors,5))
    results <- dplyr::mutate(results, lower_ci=round(exp(coef - 1.96 * SE), 5))
    results <- dplyr::mutate(results, upper_ci=round(exp(coef + 1.96 * SE), 5))
    results <- dplyr::mutate(results, "Z"=round(zvalues, 2), "P"=pvalues)
    results$var <- as.matrix(round(fisher, 5))
    # results <- dplyr::mutate(results, "Z_2"=round(zvalues2, 2),
    # "P_2"=pvalues2)
    row.names(results) <- rownames(beta)

    return(results)
}
