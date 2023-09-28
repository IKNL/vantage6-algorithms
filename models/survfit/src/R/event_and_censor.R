event_and_censor <- function(data,master){
    times <- master$times
    event <- master$event
    if(is.null(master$timepoints)){
        n.event=sapply(times, function(t) sum(data[data[master$time]==t,event]==1))
        n.censor=sapply(times, function(t) sum(data[data[master$time]==t,event]==0))
    }else{
        n.event=sapply(1:length(times), function(t) sum(data[data[master$time]>times[t-1] & data[master$time]<=times[t],event]==1))
        n.censor=sapply(1:length(times), function(t) sum(data[data[master$time]>times[t-1] & data[master$time]<=times[t],event]==0))
    }
    return(list(n.event=n.event,n.censor=n.censor))
}
