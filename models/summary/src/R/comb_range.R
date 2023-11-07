#' @export
#'
comb_range <- function(node.range, col){
    uniq.col <- unique(col)
    out = lapply(uniq.col, function(x) 0 )
    names(out) = uniq.col
    for(j in uniq.col){
        temp <- lapply(node.range, function(x) x[[j]])
        temp <- temp[!sapply(temp, is.null)]
        if(all(sapply(temp, class) == "table")){
            temp.tab <- Reduce("c", lapply(temp, function(x) x))
            out[[j]] <- tapply(temp.tab, names(temp.tab), sum)
        }else if(all(sapply(temp, class) %in% c("numeric", "integer"))){
            out[[j]] <- Reduce("range", sapply(temp, function(x) x))
        }else{
            stop("Cannot continue with other class of data outside of,
                 numeric, integer or factor.")
        }
    }
    # order the arrays or tables within the out object
    combined.range <- lapply(out, function(x){
        if(class(x) %in% c("array", "table")){
            x = x[as.character(sort(as.numeric(dimnames(x)[[1]])))]
        }else{
            x
        }
    })
    return(combined.range)
}
