#' @export
#'
RPC_N_row <- function(data, col, threshold = 5L){
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    data <- data[,cols.in.data]
    if((N <- ifelse(is.null(dim(data)), length(data), nrow(data))) < threshold){
            stop(paste0("Disclosure risk", threshold,
                        " not met for this data-set."))
    }else{
        N
    }
}
