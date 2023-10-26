rm(list = ls(all.names = TRUE))

# This seems to be equivalent to "import x as y"
library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg); library(vtg.summary)

set.seed(123L);
Data <- data.frame("X" = sample(1:10, size = 1000, replace = T),
                   "Y" = sample(c(1:3, NA), size= 1000, replace = T),
                   "Z" = sample(c(6:19, NA), size= 1000, replace = T),
                   "T" = sample(gl(10, 100), size = 1000, replace = T) )

# load("src/data/d1.rda")
# load("src/data/d2.rda")
# load("src/data/d3.rda")
#
dataset= list((d1<- Data[(1:floor(nrow(Data) / 3)), ]),
              (d2<- Data[(floor(nrow(Data) / 3)+1: floor(nrow(Data) / 3) * 2),]),
              (d3<- Data[((floor(nrow(Data) / 3) * 2) +1) : nrow(Data) ,]),
              (d4 <- data.frame("T" = rep(NA, nrow(d1)))))

# #### TEST ####
# Data <- na.omit(rbind(d1, d2, d3))
# Rchisq <- chisq.test(Data)

col = c("X", "Y", "Z", "T")
threshold = 5L

summary.mock <- function(dataset, col, threshold){
    client=vtg::MockClient$new(datasets = dataset, pkgname = 'vtg.summary')
    result=vtg.summary::dsummary(client = client,
                               col=col,
                               threshold=threshold)
    return(result)
}

res <- summary.mock(dataset = dataset,
                  col=col,
                  threshold=threshold)
