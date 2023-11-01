#' @export
#'
RPC_time=function(data, subset_rules, master){

    # data pre-processing
    data <- extend_data(data)
    data <- subset_data(data, subset_rules)
    
    time=master$time
    time2=master$time2
    tmax=master$tmax
    event=master$event
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    if(!is.na(tmax)){
        data[data[,time]>tmax ,event]=0
        data[data[,time]>tmax ,time]=tmax
    }
    times=unique(data[,time])
    return(times)
}
