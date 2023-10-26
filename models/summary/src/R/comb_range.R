#' @export
#'
comb_range <- function(node_range, col){
    uniq.col <- unique(col)
    out = lapply(uniq.col, function(x) 0 )
    names(out) = uniq.col
    for(j in col){
        temp <- lapply(node_range, function(x) x[[j]])
        temp <- temp[!sapply(temp, is.null)]
        if(all(sapply(temp, class) == "table")){
            temp.tab <- Reduce("c", lapply(temp, function(x) x))
            out[[j]] <- tapply(temp.tab, names(temp.tab), sum)
        }else if(all(sapply(temp, class) %in% c("numeric", "integer"))){
            out[[j]] <- Reduce("range", sapply(temp, function(x) x))
        }
    }
    return(out[as.character(sort(as.numeric(dimnames(out)[[1]])))])
}
