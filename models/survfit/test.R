# Clear the environment completely
rm(list = ls(all.names = TRUE))

# This seems to be equivalent to "import x as y"
library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg.survfit);library(survival);

dataset=list(vtg.survfit::D1,vtg.survfit::D2,vtg.survfit::D3)

# Data=heart
# x=floor(nrow(Data) / 3)
# d1=Data[1:x,]
# d2=Data[(x+1):(2*x),]
# d3=Data[(2*x+1):nrow(Data), ]
# dataset=list(d1,d2,d3)

# formula = Surv(time, status) ~ trt

# formula = Surv(start, stop) ~ surgery

conf.int=0.95
conf.type='log'
timepoints=NULL
plotCI=T
#timepoints = seq(0,1000,20)

survfit.mock <- function(dataset,formula,conf.type,conf.int,timepoints,plotCI){
    client=vtg::MockClient$new(datasets = dataset,pkgname = 'vtg.survfit')
    result=vtg.survfit::dsurvfit(client = client,
                                 formula=formula,
                                 conf.int = conf.int,
                                 conf.type = conf.type,
                                 timepoints = timepoints,
                                 plotCI = plotCI)
    return(result)
}

res <- survfit.mock(dataset = dataset,
             formula = formula,
             conf.int = conf.int,
             conf.type = conf.type,
             timepoints = timepoints,
             plotCI = plotCI)
