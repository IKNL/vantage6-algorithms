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
