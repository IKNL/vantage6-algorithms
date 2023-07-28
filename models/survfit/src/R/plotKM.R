plotKM=function(master,plotCI=F){
    tt=sort(unlist(sapply(master, function(s) s$times)))
    plot(x=tt,y=rep(1,length(tt)),type = 'n',ylim = c(0,1),ylab = '',xlab = '')
    for(i in 1:length(master)){
        lines(master[[i]]$times,master[[i]]$surv,type = 's',col=i)
        if(plotCI){
            lines(master[[i]]$times,master[[i]]$upper,type = 's',col=i,lty=2)
            lines(master[[i]]$times,master[[i]]$lower,type = 's',col=i,lty=2)
        }
    }
    if(length(master)>1){
        legend('topright',legend = names(master),lty = 1,col = 1:length(master))}
}