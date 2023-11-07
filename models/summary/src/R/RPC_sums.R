#' @export
#' @todo : this is a problem function, what if the data has multiple columns
#' and one is all NAS?
RPC_sums <- function(data, col, threshold = 5L){
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data
    data <- na.omit(data[, cols.in.data])
    # someitmes can have a column that is completely NA...
    if(!length(data)){
        # TODO : maybe refactor this to NAN?
        out <- NULL
    }else{
        for(j in col){
            out[[j]] <- if(!is.factor(data[,j])){
                sum(data[,j])
            }
        }
    }
    out
}
