#' @export
#'
RPC_tab <- function(data,master,stratum){
  time=master$time
  time2=master$time2
  if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
  event=master$event
  strata=master$strata
  times=master$times
  d.time = data[,time]
  d.strata = data[,strata]
  n.event <- sapply(seq(times), function(t){ sapply(seq(strata), function(s){
    if((d.time == times[t]) && (d.strata == stratum[s])){
        sum(da)
    }
    })
  })
  # n.event=sapply(times, function(t) sum(data[data[,time]==t & data[,strata]==stratum,event]==1))
  # n.censor=sapply(times, function(t) sum(data[data[,time]==t & data[,strata]==stratum,event]==0))
  n.at.risk=nrow(data[data[,strata]==stratum,])
  for(i in 2:length(times)) n.at.risk=c(n.at.risk,n.at.risk[i-1]-(n.event[i-1]+n.censor[i-1]))
  Tab=data.frame(n.event,n.censor,n.at.risk)
  names(Tab)=c('m','q','n')
  return(Tab)
}
