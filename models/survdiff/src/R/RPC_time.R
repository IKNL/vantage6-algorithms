#' @export
#'
RPC_time=function(data, subset_rules, master){

    # data pre-processing
    data <- extend_data(data)
    data <- subset_data(data, subset_rules)
    
    time=master$time
    time2=master$time2
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    times=unique(data[,time])
    return(times)
}
