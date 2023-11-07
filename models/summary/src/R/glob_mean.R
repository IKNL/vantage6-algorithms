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
