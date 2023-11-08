#' Combine NA lengths.
#'
#' Each datastation (node) sends back the number of missing value per column,
#' this function simply aggregates it.
#'
#' @param node_nas a list of node specific missing values per column
#' @param col Should be supplied by researcher as a vector of strings
#' representing the column names they think is present in the data
#'
#' @return a vector of missing values per column
#'
#' @export
#'
comb_na <- function(node_nas, col){
    uniq.col <- unique(col)
    na.list = lapply(uniq.col, function(x) 0 )
    names(na.list) = uniq.col
    for(node in seq_along(node_nas)){
        for(colName in uniq.col){
            if(colName %in% names(node_nas[[node]])){
                na.list[[colName]] <-
                    na.list[[colName]]+node_nas[[node]][colName]
            }
        }
    }
    return(Reduce("c", na.list))
}


