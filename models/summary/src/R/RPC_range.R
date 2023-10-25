#' @export
#'
RPC_range <- function(data, col, threshold = 5L) {
    uniq.col <- unique(col)
    data <- na.omit(data[, uniq.col])
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col

    for (j in uniq.col) {
        dt <- data[, j]

        if (is.factor(dt)) {
            tab <- table(dt)
            if (any(tab < threshold)) {
                stop(paste0("Disclosure risk, some values in '", j,
                            "' are lower than ", threshold))
            } else {
                out[[j]] <- tab
            }
        } else {
            out[[j]] <- range(dt)
        }
    }
    out
}
