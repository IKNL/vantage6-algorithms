#' @export
test_cox_zph <- function(
        partials=NULL,
        coxfit) {
    beta=coxfit$beta
    betavar=coxfit$betavar
    event_time = as.numeric(rep(names(coxfit$timevents),coxfit$timevents))
    if(is.null(partials)){
        # place the dots into a list
        partials <- list(...)
    }
    test = rowSums(sapply(partials, function(j) j$test))
    sum2 = sum(sapply(partials, function(j) j$sum2))
    z <- c(test^2 /(diag(betavar)*length(event_time)* sum2))
    z.ph <- cbind(z,1,1- pchisq(z,1))
    if (length(beta)>1) {
        gtest = rowSums(sapply(partials, function(j) j$gtest))
        z <- c(gtest %*% betavar %*% gtest) * length(event_time) / sum2
        z.ph <- rbind(z.ph, c(z, length(beta),1-pchisq(z, length(beta))))
        dimnames(z.ph) <- list(c(row.names(coxfit$betavar), "GLOBAL"),
                               c( "chisq",'df', "p"))
    }
    SCH=c()
    for(i in 1:length(partials)) SCH=rbind(SCH,partials[[i]]$SCH)
    SCH=SCH[order(SCH$time),-1]
    sch_residuals=as.matrix(SCH) %*% betavar*nrow(SCH) + rep(as.vector(beta),
                                                             each=nrow(SCH))
    colnames(sch_residuals)=names(SCH)
    jpeg(filename = "coxzph_plot%03d.jpg", width = 960, height = 960,
         quality = 70)
    vtg.coxzph::plot_cox_zph(cox_zph = list(event_time=event_time,
                                            sch_residuals=sch_residuals,
                                            beta=beta,
                                            betavar=betavar,
                                            transform=coxfit$transform))
    dev.off()
    return(round(z.ph,3))
}