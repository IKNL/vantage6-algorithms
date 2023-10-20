#' @export
#'
RPC_time=function(data,master){
    time=master$time
    time2=master$time2
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    times=unique(data[,time])
    return(times)
}
