rm(list = ls(all.names = TRUE))

library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg);library(vtg.summary)

set.seed(123L);
Data <- data.frame("X" = sample(1:10, size = 999, replace = T),
                   "Y" = sample(c(1:3, NA), size= 999, replace = T),
                   "Z" = sample(c(6:19, NA), size= 999, replace = T),
                   "T" = sample(gl(10, 100), size = 999, replace = T) )

dataset= list((d1<- Data[(1:333), ]),
              (d2<- Data[(334:667),]),
              (d3<- Data[(668:999) ,]),
              (d4 <- data.frame("T" = rep(NA, nrow(d1)))))


col = c("X", "Y", "Z", "T")
threshold = 5L
types=NULL

summary.mock <- function(dataset, col, threshold, types){
    client=vtg::MockClient$new(datasets = dataset, pkgname = 'vtg.summary')
    result=vtg.summary::dsummary(client = client,
                               col=col,
                               threshold=threshold,
                               types=types)
    return(result)
}

res <- summary.mock(dataset = dataset,
                  col=col,
                  threshold=threshold,
                  types=types)
