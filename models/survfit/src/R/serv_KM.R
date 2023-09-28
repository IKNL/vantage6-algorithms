serv_KM=function(nodes=NULL,master=NULL){
    s = Reduce(`+`, lapply(nodes, function(j) j$s))
    r = Reduce(`+`,lapply(nodes, function(j) j$r))

    surv=1-(s[1])
    for(i in 2:length(master$times)) surv=c(surv,surv[i-1]*(1-s[i]))

    std.err=surv[1]*sqrt(r[1])
    for(i in 2:length(master$times)) std.err=c(std.err,surv[i]*sqrt(r[i]+(std.err[i-1]/surv[i-1])^2))
    std.err=std.err/surv
    master$surv=surv
    master$std.err=std.err

    if(master$conf.type=='plain'){
        master$lower=pmax(0, pmin(1, surv - std.err*surv * qnorm(1-(1-master$conf.int)/2)))
        master$upper=pmin(1, pmax(0, surv + std.err*surv * qnorm(1-(1-master$conf.int)/2)))
    }
    if(master$conf.type=='log'){
        master$lower=pmin(1, exp(log(surv) - std.err * qnorm(1-(1-master$conf.int)/2)))
        master$upper=pmax(0, exp(log(surv) + std.err * qnorm(1-(1-master$conf.int)/2)))
    }
    if(master$conf.type=='loglog'){
        master$lower=exp(-exp(log(-log(surv)) - std.err/surv/log(surv) * qnorm(1-(1-master$conf.int)/2)))
        master$upper=exp(-exp(log(-log(surv)) + std.err/log(surv) * qnorm(1-(1-master$conf.int)/2)))
    }
    master$upper = ifelse(master$upper > 1, 1, master$upper)
    master$upper = ifelse(master$upper < 0, 0, master$upper)
    master$lower = ifelse(master$lower > 1, 1, master$lower)
    master$lower = ifelse(master$lower < 0, 0, master$lower)

    return(master)
}