RPC_time=function(data,subset_rules,master,stratum=NULL){

    # data pre-processing
    data <- extend_data(data)
    data <- subset_data(data, subset_rules)

    time=master$time
    time2=master$time2
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    event=master$event
    if(is.na(master$strata)){
        times=unique(data[,time])
    }else{
        times=unique(data[data[,master$strata]==stratum,time])
    }
    return(times)
}
