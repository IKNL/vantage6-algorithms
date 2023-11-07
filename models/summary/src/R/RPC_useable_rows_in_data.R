#' @export
#'
RPC_useable_rows_in_data <- function(data, col, threshold = 5L){
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    data <- na.omit(data[,cols.in.data])
    # if the number of columns in a dataset is 1 then there won't be a
    # dimension to the data.
    n.useable.rows <- if(is.null(dim(data))){
        length(data)
    }else{
        nrow(data)
    }
    if(n.useable.rows == 0 || n.useable.rows > threshold){
        return(n.useable.rows)
    }else if(n.useable.rows < threshold){
        stop(paste0("Disclosure risk as there are fewer than ", threshold,
                    " observations."))
    }else{
        stop("Cannot execute algorithm with this data...")
    }
}
