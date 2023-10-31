#' @export
#'
RPC_schoenfeld_residuals <- function(data,subset_rules,time,event,coxfit){

    # data pre-processing
    data <- extend_data(data)
    data <- subset_data(data, subset_rules)

    case <- data[,event]==1
    data_at_time <- data[which(case),time]
    n <- length(data_at_time)
    event_time <- as.numeric(rep(names(coxfit$timevents),coxfit$timevents))
    index_event <- sapply(1:n,function(i){
        which(event_time%in%data_at_time[i])[1]
        })
    schoenfeld <- data[case,row.names(coxfit$beta)]-coxfit$ratio[index_event,]
    ss_res <- (as.matrix(schoenfeld) %*% coxfit$betavar) * length(event_time)
    # diff <- data_at_time - mean(event_time)
    if(coxfit$transform=='log'){
        diff=log(data_at_time)-mean(log(event_time))
    }
    if(coxfit$transform=='rank'){
        diff=rank(data_at_time)-mean(rank(event_time))
    }
    if(coxfit$transform=='identity'){
        diff=(data_at_time)-mean((event_time))
    }
    t_statistic <- diff %*% ss_res
    sx2 <- sum(diff^2)
    schoenfeld_res <- diff %*% as.matrix(schoenfeld)
    return(
        list(
            test=t_statistic, sum2=sx2, gtest=schoenfeld_res,
            SCH=cbind(
                time=event_time[index_event],
                schoenfeld)
            )
        )
}
