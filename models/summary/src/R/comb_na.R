comb_na <- function(node_nas, col){
    uniq.col <- unique(col)
    na.list = lapply(uniq.col, function(x) 0 )
    names(na.list) = uniq.col
    for(x in seq(length(node_nas))){
        for(j in col){
            na.list[[j]] = na.list[[j]] + sapply(node_nas[[x]][[j]], function(l) l)
        }
    }
    na.list
}

