rm(list = ls(all.names = TRUE))

# This seems to be equivalent to "import x as y"
library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg.crosstab)

data <- data.frame(Type = paste0("T", rep(1:4, 9*4)),
                   Subj = gl(9, 4, 36*4),event=rbinom(36*4,1,.5))
data$Subj=as.numeric(data$Subj)
D1  <- data[data$Subj%in%c(1,2,3), ]
D2  <- data[data$Subj%in%c(4,5,6), ]
D3  <- data[data$Subj%in%c(7,8,9), ]

dataset = list(D1,D2,D3)

formula = as.formula(~ Type + Subj + event)

crosstab.mock <- function(dataset,formula){
    client=vtg::MockClient$new(datasets = dataset,pkgname = 'vtg.crosstab')
    result=vtg.crosstab::dct(client = client,f = formula,
                             organizations_to_include = NULL)
    return(result)
}

res <- crosstab.mock(dataset = dataset, formula = formula)
# compare to... works!
xtabs(formula,data)
