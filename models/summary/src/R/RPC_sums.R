#' @export
#' @todo : this is a problem function, what if the data has multiple columns
#' and one is all NAS?
RPC_sums <- function(data, col, threshold = 5L){
    uniq.col <- unique(col)
    # could be that not each 'col' is not the dataset
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data
    # someitmes can have a column that is completely NA...
    if(!length(data)){
        # TODO : maybe refactor this to NAN?
        out <- NULL
    }else{
        for(colName in cols.in.data){
            if(!is.factor(data[,colName])){
                out[[colName]] <- sum(na.omit(data[, colName]))
            }else if(is.factor(data[,colName])){
                cat("Cannot compute sums of factor data: ", colName)
            }
        }
    }
    return(out)
}
