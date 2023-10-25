#' @export
#'
RPC_sqr_dev <- function(data, col, glob_mu){
    uniq.col <- unique(col)
    data <- na.omit(data[, uniq.col])
    out <- vector("list", length(uniq.col))
    for(j in uniq.col){
        out[[j]] <- if(!is.factor(data[,j])){
            sum((data[,j] - glob_mu[[j]])^2)
        }
    }
    out
}
