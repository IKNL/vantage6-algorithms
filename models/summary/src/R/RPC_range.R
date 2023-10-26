#' @export
#'
RPC_range <- function(data, col, threshold = 5L) {
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data
    data <- na.omit(data[, cols.in.data])
    if(!length(data)){
        out <- NULL
    }else{
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
    }
    out
}
