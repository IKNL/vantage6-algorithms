#' @export
#'
glob_var <- function(glob_sqr_dev, Nglob, col){
    uniq.col <- unique(col)
    data <- na.omit(data[, uniq.col])
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col
    for(j in uniq.col){
        out[[j]] <- if(!((xsqr <- glob_sqr_dev[[j]]) == 0)){
            xsqr / (Nglob[[j]] - 1)
        }
    }
    out
}
