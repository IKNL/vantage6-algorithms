#' @export
#'
comb_sums <- function(node_sums, col){
    uniq.col <- unique(col)
    data <- na.omit(data[, uniq.col])
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col
    for(j in col){
        temp <- lapply(node_sums, function(x) x[[j]])
        out[[j]] <- Reduce("sum", lapply(temp, function(x) x))
    }
    out
}
