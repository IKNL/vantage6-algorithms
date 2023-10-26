#' @export
#'
RPC_get_NA <- function(data, col){

    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    out <- vector("list", length(cols.in.data))
    names(out) <- cols.in.data

    for(j in cols.in.data){
        if(any(is.na(data[,j]))){
            na.pos <- which(is.na(data[,j]))
            out[[j]] <- length(na.pos)
        }
    }
    out
}
