#' @export
#'
RPC_sums <- function(data, col, threshold = 5L){
    uniq.col <- unique(col)
    data <- na.omit(data[, uniq.col])
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col
    for(j in col){
        out[[j]] <- if(!is.factor(data[,j])){
            sum(data[,j])
        }
    }
    out
}
