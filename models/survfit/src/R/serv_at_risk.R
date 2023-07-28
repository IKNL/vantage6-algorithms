serv_at_risk=function(nodes=NULL,master=NULL){
    master$n.at.risk=rowSums(sapply(nodes, function(s) s$n.at.risk))
    master$n.events=sum(sapply(nodes, function(s) s$event))
    return(master)
}