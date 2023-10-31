#' node-side function used further in calculatin of Hazard Ratio.
#' @export
#'
RPC_ratio=function(data,subset_rules,time,event,coxfit){

    # data pre-processing
    data <- extend_data(data)
    data <- subset_data(data, subset_rules)

    beta=coxfit$beta
    betavar=coxfit$betavar
    # order the data according to the event times
    data <- data[order(data[,time]), ]
    event_time=data[which(data[,event]==1),time]
    # used in calculation of the hazard ratio
    numerator=apply(as.matrix(data[,row.names(beta)]),2,function(i){
        i*exp(as.matrix(data[,row.names(beta)])%*%beta)
        }
    )
    denominator=exp(as.matrix(data[,row.names(beta)])%*%beta)
    num=c()
    den=c()
    for(j in coxfit$timevents) {
        #for(j in timevents) {
        risk_set <- which(j<=data[,time])
        if(length(risk_set)>0){
            if(length(risk_set)>1){
                num <- rbind(num,colSums(numerator[risk_set,]))
                den <- c(den,sum(denominator[risk_set]))
            }else{
                num <- rbind(num,(numerator[risk_set,]))
                den <- c(den,(denominator[risk_set]))
            }
        }else{
                num <- rbind(num, 0)
                den <- c(den, 0)
        }
    }
    return(
        list(
            t=table(factor(event_time,levels = coxfit$timevents)),
            n=num,
            d=den
            )
    )
}
