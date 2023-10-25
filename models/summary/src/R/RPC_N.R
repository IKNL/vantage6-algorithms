#' @export
#'
RPC_N <- function(data, col, threshold = 5L){
    uniq.col <- unique(col)
    data <- na.omit(data[, uniq.col])
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col

    for(j in uniq.col){
        out[[j]] <- if(!is.factor(data[,j])){
            if((N <- length(data[,j])) < threshold){
                stop(paste0("Disclosure risk, not enough observations in ", "j"
                            ,"<", threshold))
            }else{
                N
            }
        }
    }
    out
}
