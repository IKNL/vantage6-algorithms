#' Compute/count the *global* number of ties at each time point using the
#' tie-counts from the individual sites.
#'
#' Params:
#'   Ds: list of *local* tie-counts, indexed by site nr
#'
#' Return:
#'   numeric vector with tie-counts and named index with unique
#'   event times
compute.combined.ties <- function(Ds) {

    # Merge the list of event times & counts into a single data frame
    for (k in 1:length(Ds)) {
        # This only works if the joined columns have different names
        site_name <- sprintf("site_%i", k)
        colnames(Ds[[k]]) <- c("time", site_name)

        if (k == 1) {
            D <- Ds[[k]]
        } else {
            D <- merge(D, Ds[[k]], by="time", all=T)
        }
    }

    # Cast the time column to numeric to enable proper sorting
    D[, "time"] <- as.numeric(D$time)
    D <- D[order(D$time), ]

    # Set the time column as the index
    rownames(D) <- D$time

    # Drop the time column; drop=F ensures that the data frame is not
    # coerced to a vector in case of a single column.
    D <- D[, -1, drop=F]

    # The merge/join will have introduced NAs: set these to 0
    D[is.na(D)] <- 0

    # Sum the columns to get the total nr of ties for each time
    D_all <- rowSums(D)

    return(D_all)
}

