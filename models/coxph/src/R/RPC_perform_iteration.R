#' Compute the three aggretated statistics needed for an iteration
#'
#' Params:
#'   df: dataframe
#'   expl_vars: list of explanatory variables (covariates) to use
#'   time_col: name of the column that contains the event/censor times
#'   censor_col: name of the colunm that explains whether an event occured or
#'               the patient was censored
#'   beta: vector of beta coefficients (length(beta) == length(expl_vars))
#'   times: vector of *globally* unique event times
#'
#' Return:
#'   list containing aggretated statistics
RPC_perform_iteration <- function(df, expl_vars, time_col, censor_col, beta, unique_event_times) {
    data <- preprocess.data(df, expl_vars, censor_col, time_col)

    D <- length(unique_event_times)
    m <- length(expl_vars)

    # initialize matrices for the aggregates we're about to compute
    agg1 <- array(dim=c(D), 0)
    agg2 <- array(dim=c(D, m), 0)
    dimnames(agg2) <- list(NULL, expl_vars)

    agg3 <- array(dim=c(D, m, m), 0)
    dimnames(agg3) <- list(NULL, expl_vars, expl_vars)

    for (i in 1:D) {
        cat('.')
        # Compute the risk set at time t; this includes *all* patients that have a
        # survival time greater than or equal to the current time
        R_i <- as.matrix(data$Z[data$time >= unique_event_times[i], ])

        if (nrow(R_i) == 0) {
            break
        }

        # aggregate 1: SUM_risk[exp(beta * z)]
        ebz <- exp(R_i %*% beta)
        agg1[i] <- sum(ebz)

        # aggregate 2: SUM_risk[z_r *exp(beta * z)]
        # Use apply to multiply each column (element-wise) in R_i with ebz
        z_ebz <- apply(R_i, 2, '*', ebz)

        # Undo the simplification that `apply` does in case of a single row in R_i
        if (nrow(R_i) == 1) {
            z_ebz <- t(z_ebz)
        }

        agg2[i, ] <- colSums(z_ebz)

        # aggregate 3: SUM_risk[z_r * z_q * exp(beta * z)]
        summed <- matrix(0, nrow=m, ncol=m)
        for (j in 1:nrow(R_i)) {
            # z_ebz[j, ]: numeric vector
            # the outer product creates a matrix:
            # | z1*z1 | z1*z2 | ... | z1*zm |
            # | z2*z1 | z2*z2 | ... | z2*zm |
            # | ...   | ...   | ... | ...   |
            # | zm*z1 | zm*z2 | ... | zm*zm |
            summed <- summed + z_ebz[j, ] %*% t(R_i[j, ])
        }

        agg3[i, , ] <- summed
    }

    writeln('')

    return(
        list(
            agg1=agg1,
            agg2=agg2,
            agg3=agg3
        )
    )
}

