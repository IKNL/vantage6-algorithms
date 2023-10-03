#' extract hazard ratio
#' @importMethodsFrom   left_join
#' @export
#'
hazard_ratio=function(nodes=NULL, coxfit=NULL){
    if(is.null(nodes))  {
        # place the dots into a list
        x <- list(...)
    }else{
        x <- nodes
    }
    timevents = rowSums(sapply(nodes, function(i) i$t))
    num=lapply(nodes,function(s){
        app=left_join(data.frame(t=names(timevents)), data.frame(
            t=names(s$t),s$n),by='t'
            )
        app=apply(app[,-1], 2, rep,times=timevents)
        return(app)
        })
    den=lapply(nodes,function(s){
        app=left_join(data.frame(t=names(timevents)), data.frame(
            t=names(s$t),s$d),by='t'
            )
        app=rep(app[,-1],times=timevents)
        return(app)})
    num=Reduce("+", num)
    den=Reduce("+", den)
    coxfit$timevents=timevents
    coxfit$ratio=num/den
    return(coxfit)
}