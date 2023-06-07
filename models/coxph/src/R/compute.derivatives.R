#' Compute the primary derivative (vector of length beta)
compute.derivatives <- function(z_hat, D_all, aggregates) {

    # Sum the aggregate statistics for each site
    for (k in 1:length(aggregates)) {
        if (k == 1) {
            summed_agg1 <- aggregates[[k]]$agg1
            summed_agg2 <- aggregates[[k]]$agg2
            summed_agg3 <- aggregates[[k]]$agg3
        } else {
            summed_agg1 <- summed_agg1 + aggregates[[k]]$agg1
            summed_agg2 <- summed_agg2 + aggregates[[k]]$agg2
            summed_agg3 <- summed_agg3 + aggregates[[k]]$agg3
        }
    }

    # summed_agg1: vector with scalar for each time point
    # summed_agg2: vector of length m for each time point
    # summed_agg3: matrix of size (m x m) for each time point
    for (i in 1:length(D_all)) {
        # primary
        s1 <- D_all[[i]] * (summed_agg2[i, ] / summed_agg1[i])

        # secondary
        first_part <- (summed_agg3[i, , ] / summed_agg1[i])

        # the numerator is the outer product of agg2
        numerator <- summed_agg2[i, ] %*% t(summed_agg2[i, ])
        denominator <- summed_agg1[i] * summed_agg1[i]
        second_part <- numerator / denominator

        s2 <- D_all[[i]] * (first_part - second_part)

        if (i == 1) {
            total_p1 <- s1
            total_p2 <- s2

        } else {
            total_p1 <- total_p1 + s1
            total_p2 <- total_p2 + s2
        }
    }

    primary_derivative <- z_hat - total_p1
    secondary_derivative <- -total_p2

    return(list(
        primary=primary_derivative,
        secondary=secondary_derivative
    ))
}
