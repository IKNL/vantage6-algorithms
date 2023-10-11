RPC_KMsurv=function(data,master,stratum=NULL){
    #data=D3
    time=master$time
    time2=master$time2
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    event=master$event
    n.at.risk=master$n.at.risk
    if(!is.na(master$strata)){
        data=data[data[,master$strata]==stratum,]
    }
    data=data[order(data[,time]),]
    times=master$times

    ev_cen=event_and_censor(data=data,master=master)
    n.event=ev_cen$n.event
    n.censor=ev_cen$n.censor

    s=(n.event/n.at.risk)
    r=n.event/(n.at.risk*(n.at.risk-n.event))
    return(list(s=s,r=r))
}