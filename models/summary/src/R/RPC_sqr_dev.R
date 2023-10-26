#' @export
#'
RPC_sqr_dev <- function(data, col, glob_mu){
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data
    data <- na.omit(data[, cols.in.data])
    if(!length(data)){
        out <- NULL
    }else{
        for(j in uniq.col){
            out[[j]] <- if(!is.factor(data[,j])){
                sum((data[,j] - glob_mu[[j]])^2)
            }
        }
    }
    out
}
