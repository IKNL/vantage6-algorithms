#' @export
#'
RPC_sqr_dev <- function(data, col, glob.mean){
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data
    # check if there is any data that is not NA
    if(!length(na.omit(data[,cols.in.data]))){
        out <- NaN
    }else{
        for(colName in cols.in.data){
            # factor data cannot be used to calculate squared deviance
            if (!is.factor(data[, colName])) {
                out[[colName]] <- sum((data[, colName]-glob.mean[[colName]])^2,
                                      na.rm = T)
            }else {
                cat("The column,", colName, "is a factor...")
                out[[colName]] <- NA
            }
        }
    }
    sqr.dev <- Reduce("c", out)
    names(sqr.dev) <- names(out)
    return(sqr.dev)
}
