# Clear the environment completely
rm(list = ls(all.names = TRUE))

# This seems to be equivalent to "import x as y"
library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg.survfit)

dataset=list(vtg.survfit::D1,vtg.survfit::D2,vtg.survfit::D3)
###exapl

formula = Surv(time, status) ~ trt
#formula = Surv(time,time2, status) ~ trt

conf.int=0.95
conf.type='log'
timepoints=NULL
plotCI=T
tmax=100
#timepoints = seq(0,1000,20)

survfit.mock <- function(dataset,formula,conf.type,conf.int,timepoints,plotCI,tmax){
    client=vtg::MockClient$new(datasets = dataset,pkgname = 'vtg.survfit')
    result=vtg.survfit::dsurvfit(client = client,
                                 formula=formula,
                                 conf.int = conf.int,
                                 conf.type = conf.type,
                                 timepoints = timepoints,
                                 plotCI = plotCI,
                                 tmax=tmax)
    return(result)
}

res <- survfit.mock(dataset = dataset,
             formula = formula,
             conf.int = conf.int,
             conf.type = conf.type,
             timepoints = timepoints,
             plotCI = plotCI,
             tmax=tmax)
