#' @export
#'
RPC_len_col <- function(data, col, threshold = 5L){
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data
    data <- na.omit(data[, cols.in.data])
    # someitmes can have a column that is completely NA...
    if(!length(data)){
        out <- NULL
    }else{
        for(j in cols.in.data){
            out[[j]] <- if(!is.factor(data[,j])){
                if((N <- length(data[,j])) < threshold){
                    stop(paste0("Disclosure risk, not enough observations in ",
                                "j" ,"<", threshold))
                }else{
                    N
                }
            }
        }
    }

    out
}
