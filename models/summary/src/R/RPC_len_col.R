#' @export
#'
RPC_len_col <- function(data, col, threshold = 5L){
    # extract only unique columns in case there are repeats
    uniq.col <- unique(col)
    # can have that not all the data share the same columns
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    # so there is an association with named list items
    list.of.column.lengths <- vector("list", length(cols.in.data))
    names(list.of.column.lengths) <- cols.in.data
    assigns.column.lengths <- lapply(colnames(data), function(colName){
        # we want to return 0 for columns entierly populated by NA
        # so that we know not to use them in the calculation later on...
        length.of.columns <- length(na.omit(data[, colName]))
        if(length.of.columns == 0){
            assigned.length <- as.vector(0)
        }else if (length.of.columns > threshold){
            assigned.length <- as.vector(length.of.columns)
        }else if(length.of.columns < threshold) {
            stop(paste("Disclosure risk, not enough observations in",
                        colName, "<", threshold))
        }else{
            stop("Cannot compute the length of this object, check the input.")
        }
        names(assigned.length) <- colName
        return(assigned.length)
    })
    # to access the vector easily
    column.lengths <- Reduce("c", assigns.column.lengths)
    return(column.lengths)
}
