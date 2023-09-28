RPC_at_risk <- function(data,master,stratum=NULL){
    time=master$time
    event=master$event
    if(!is.na(master$strata)){
       data=data[data[,master$strata]==stratum,]
    }
    data=data[order(data[,time]),]
    times=master$times
    ev_cen=event_and_censor(data=data,master=master)
    n.event=ev_cen$n.event
    n.censor=ev_cen$n.censor
    n.at.risk=nrow(data)

    for(i in 2:length(times)) n.at.risk=c(n.at.risk,n.at.risk[i-1]-(n.event[i-1]+n.censor[i-1]))
    return(list(n.at.risk=n.at.risk,event=sum(n.event)))
}
#lapply(dataset, RPC_at_risk,master=master,stratum=stratum)