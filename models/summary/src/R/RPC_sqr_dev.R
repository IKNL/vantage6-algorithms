#' Calculate Squared Deviance.
#'
#' This function is the precursor to getting the summed squared deviance
#' across all the datastation(s) (node). This is then used to calculate the
#' variance and following that, the standard deviation.
#'
#' @param data Dataset
#' @param col Should be supplied by researcher as a vector of strings
#' representing the column names they think is present in the data
#' @param glob.mean This is calculated earlier in the algorithm, global mean
#' of the combined datastation(s) (nodes).
#' @param types containing the types to set to the columns
#'
#' @return Vector of squared deviance per column in the Data or NaN if the
#' data is populated entirely by NA
#'
RPC_sqr_dev <- function(data, col, glob.mean, types=NULL){
    if(!is.null(types)) data <- vtg.summary::assign_types(data, types)
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data
    # check if there is any data that is not NA
    if(!length(na.omit(data[,cols.in.data]))){
        out <- NaN
    }else{
        for(colName in cols.in.data){
            dt <- data[,colName]
            # factor data cannot be used to calculate squared deviance
            if ((!is.factor(dt)) && (is.numeric(dt))){
                out[[colName]] <- sum((dt-glob.mean[[colName]])^2,
                                      na.rm = T)
            }else if((is.factor(dt)) || is.na(dt)){
                out[[colName]] <- NA
            }else{
                stop("Cannot compute squared deviance with other data type...")
            }
        }
    }
    sqr.dev <- Reduce("c", out)
    names(sqr.dev) <- names(out)
    return(sqr.dev)
}
