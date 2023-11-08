#' Combine Sums
#'
#' Function to aggregate the datastation (node) specific sums per column.
#'
#' @param node.list.to.sum is the node specific sum per column. This is a list.
#' @param col Should be supplied by researcher as a vector of strings
#' representing the column names they think is present in the data
#'
#' @return named vector of aggregated sums.
#'
#' @export
#'
comb_sums <- function(node.list.to.sum, col){
    uniq.col <- unique(col)
    list.of.sums <- vector("list", length(uniq.col))
    names(list.of.sums) <- uniq.col
    for(j in uniq.col){
        temp <- lapply(node.list.to.sum, function(x){
            if(!is.na(x[j])){
                x[[j]]
            }
        })
        # to see which values are valid or not
        find.na.or.nulls <- sapply(temp, function(value){
         if((is.na(value)) || (is.nan(value)) || is.null(value)){
             T
         }else{
             F
         }
        })
        # Because not every value can be assigned NaN and 0 is sometimes
        # valid if values are greater than or less than 0...
        temp <- lapply(seq(length(temp)), function(x){
            if(isTRUE(find.na.or.nulls[[x]])){
                NaN
            }else{
                temp[[x]]
            }
        })
        list.of.sums[[j]] <- if(all(is.na(sapply(temp, function(x) x)))){
            NaN
        }else{
            Reduce("sum", lapply(temp, function(x) x[!is.na(x)]))
        }

    }
    vec.of.sums <- Reduce("c", list.of.sums)
    names(vec.of.sums) <- names(list.of.sums)
    return(vec.of.sums)
}
