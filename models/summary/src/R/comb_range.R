#' Function to combine range(s) of the columns.
#'
#' This function combines the ranges sent back by each datastation (node)
#' based on the type of range. Here it can be two unique cases: a table for
#' factor data or a numeric/integer in which case the simple min/max of each
#' datasation per unique column is aggregated.
#'
#' @param node.range these are the node specific range(s) per column. This is
#' a list of either a vector with 2 distinct values (min, max) or a table
#' for factor data of the number of unique instances of each factor level.
#' @param col Should be supplied by researcher as a vector of strings
#' representing the column names they think is present in the data
#'
#' @return list of combined ranges.
#'
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
