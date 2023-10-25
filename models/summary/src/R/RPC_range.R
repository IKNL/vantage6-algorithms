RPC_range <- function(data, col, threshold = 5L) {
    uniq.col <- unique(col)
    data <- na.omit(data[, uniq.col])
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col

    for (column in uniq.col) {
        dt <- data[, column]

        if (is.factor(dt)) {
            tab <- table(dt)
            if (any(tab < threshold)) {
                stop(paste0("Disclosure risk, some values in '", column, "' are lower than ", threshold))
            } else {
                out[[column]] <- tab
            }
        } else {
            out[[column]] <- range(dt)
        }
    }
    return(out)
}
