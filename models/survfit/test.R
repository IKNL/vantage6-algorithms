# Clear the environment completely
rm(list = ls(all.names = TRUE))

# This seems to be equivalent to "import x as y"
library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg.basic)

dataset=list(vtg.survfit::D1,vtg.survfit::D2,vtg.survfit::D3)

formula = Surv(time, status) ~ trt
conf.int=0.95
conf.type='log'
timepoints=NULL
plotCI=T
#timepoints = seq(0,1000,20)

survfit.mock=function(dataset,formula,conf.type,conf.int,timepoints,plotCI){
    client=vtg::MockClient$new(datasets = dataset,pkgname = 'vtg.survfit')
    result=vtg.survfit::dsurvfit(client = client,
                                 formula=formula,
                                 conf.int = conf.int,
                                 conf.type = conf.type,
                                 timepoints = timepoints,
                                 plotCI = plotCI)
    return(result)
}

survfit.mock(dataset = dataset,
             formula=formula,
             conf.int = conf.int,
             conf.type = conf.type,
             timepoints = timepoints,
             plotCI = plotCI)
