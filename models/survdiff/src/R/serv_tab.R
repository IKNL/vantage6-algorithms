#' @export
#'
serv_tab=function(nodes=NULL,master=NULL){
    master=Reduce(x=nodes,f = '+')
    return(master)
}
