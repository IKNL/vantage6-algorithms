#' @export
#'
glob_mean <- function(sumsglob, Nglob, col){
    uniq.col <- unique(col)
    out <- vector("list", length(uniq.col))
    names(out) <- uniq.col

    for(j in uniq.col){
        out[[j]] <- if(!(sumsglob[[j]] == 0)){
            sumsglob[[j]] / Nglob[[j]]
        }
    }
    out
}
