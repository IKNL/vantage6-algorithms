#' Global Mean.
#'
#' Function to compute the global mean from aggregated sums and lengths of each
#' column.
#'
#' @param glob.sums is the global sum per column.
#' @param glob.lens is the global lengths of each column.
#' @param col Should be supplied by researcher as a vector of strings
#' representing the column names they think is present in the data
#'
#' @return named vector of global mean per column.
#'
#' @export
#'
glob_mean <- function(glob.sums, glob.lens, col){
    uniq.col <- unique(col)
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col
    for(j in uniq.col){
        out[[j]] <- if((glob.sums[j] == 0) || (glob.lens[j] == 0) || (is.nan(glob.sums[j]))){
            NaN
        }else{
            glob.sums[[j]] / glob.lens[[j]]
        }
    }
    global.mean <- Reduce("c", out)
    names(global.mean) <- names(out)
    return(global.mean)
}
