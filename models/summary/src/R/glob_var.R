#' Global Variance.
#'
#' Function to compute the global variance from global squared deviance and
#' global lengths
#'
#' @param glob.sqr.dev is the global squared deviance per column.
#' @param glob.lens is the global lengths of each column.
#' @param col Should be supplied by researcher as a vector of strings
#' representing the column names they think is present in the data
#'
#' @return named vector of global variance per column.
#'
#' @export
#'
glob_var <- function(glob.sqr.dev, glob.lens, col){
    uniq.col <- unique(col)
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col
    for(j in uniq.col){
        xsqr <- glob.sqr.dev[j]
        out[[j]] <- if((glob.sqr.dev[j] == 0)||is.nan(glob.sqr.dev[j])){
            NaN
        }else{
            xsqr / (glob.lens[j] - 1)
        }
    }
    glob.var <- Reduce("c", out)
    names(glob.var) <- names(out)
    return(glob.var)
}
