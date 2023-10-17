plotKM <- function(master, plotCI=F){
    temp.master <- lapply(seq(nrow(master$Tab)), function(x) master[[x]])
    names(temp.master) <- names(master)[seq(nrow(master$Tab))]
    tt=sort(unlist(sapply(temp.master, function(s) s$times)))
    plot(x=tt, y=rep(1,length(tt)), type='n', ylim=c(0,1),
         ylab='Survival probability', xlab='Time', main="Kaplan-Meier",
         cex.lab=1, cex.main=2, las=1)
    for(i in 1:length(temp.master)){
        lines(temp.master[[i]]$times, temp.master[[i]]$surv, type='s', col=i,
              lwd=2)
        if(plotCI){
            lines(temp.master[[i]]$times, temp.master[[i]]$upper, type='s',
                  col=i, lty=2, lwd=2)
            lines(temp.master[[i]]$times, temp.master[[i]]$lower, type='s',
                  col=i, lty=2, lwd=2)
        }
    }
    if(length(temp.master)>1){
        legend('topright', legend=names(temp.master), lty=1, lwd=2,
               col = 1:length(temp.master))
    }
}