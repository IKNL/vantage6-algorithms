#' @export
#'
RPC_sqr_dev <- function(data, col, glob.mean){
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data
    data <- na.omit(data[, cols.in.data])
    if(!length(data)){
        out <- NaN
    }else{
        for(j in uniq.col){
            # factor data cannot be used to calculate squared deviance
            out[[j]] <- if(is.factor(data[,j])){
                cat("The column,", j, "is a factor...")
                NA
            }else if((!is.factor(data[,j])) &&  all(is.finite(data[,j]))){
                sum((data[,j] - glob.mean[[j]])^2)
            }else{
                stop("Cannot compute squared deviance...")
            }
        }
    }
    sqr.dev <- Reduce("c", out)
    names(sqr.dev) <- names(out)
    return(sqr.dev)
}
