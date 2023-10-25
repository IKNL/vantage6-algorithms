#' @export
#'
comb_N <- function(node_N, col){
    uniq.col <- unique(col)
    out = lapply(uniq.col, function(x) 0 )
    names(out) = uniq.col
    for(j in uniq.col){
        out[[j]] <- Reduce("sum",lapply(node_N, function(x) x[[j]]) )
    }
    out
}
