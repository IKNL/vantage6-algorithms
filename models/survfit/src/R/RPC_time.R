RPC_time=function(data,master,stratum=NULL){
    time=master$time
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    event=master$event
    if(is.na(master$strata)){
        times=unique(data[,time])
    }else{
        times=unique(data[data[,master$strata]==stratum,time])
    }
    return(times)
}
