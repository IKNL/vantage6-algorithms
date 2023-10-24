rm(list = ls(all.names = TRUE))

# This seems to be equivalent to "import x as y"
library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg); library(vtg.chisq)

# set.seed(123L);
# Data <- data.frame("X" = sample(1:10, size = 1000, replace = T),
#                    "Y" = sample(c(1:3, NA),size= 1000, replace = T),
#                    "Z" = sample(c(6:19, NA),size= 1000, replace = T))

load("src/data/d1.rda")
load("src/data/d2.rda")
load("src/data/d3.rda")

dataset= list(d1, d2, d3)

#### TEST ####
Data <- na.omit(rbind(d1, d2, d3))
Rchisq <- chisq.test(Data)

col = c("X", "Y", "Z")
threshold = 5L
probs=NULL

chisq.mock <- function(dataset,col, threshold, probs){
    client=vtg::MockClient$new(datasets = dataset,pkgname = 'vtg.chisq')
    result=vtg.chisq::dchisq(client = client,
                                 col=col,
                                 threshold=threshold,
                                 probs=probs)
    return(result)
}

res <- chisq.mock(dataset = dataset,
                    col=col,
                    threshold=threshold,
                    probs=probs)
res$statistic == Rchisq$statistic
res$parameter == Rchisq$parameter
res$pval == Rchisq$p.value
