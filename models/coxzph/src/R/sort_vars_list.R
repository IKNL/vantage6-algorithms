#' server-side function but should probably be nodeside...
#' @export
#'
sort_vars_list=function(nodes=NULL,coxfit=NULL){
    if(is.null(nodes))  {
        x <- list(...)  #place the dots into a list
    }else{
        x <- nodes
    }
    coxfit$timevents = sort(unique(unlist(nodes)))
    return(coxfit)
}