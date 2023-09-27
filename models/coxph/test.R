rm(list=ls(all.names = T))
library(vtg.coxph);library(dplyr);library(vtg);library(survival);
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

Data <- read.table("https://stats.idre.ucla.edu/stat/r/examples/asa/hmohiv.csv"
                   , sep=",", header = TRUE)
regfit <-  coxph(Surv(time, censor)~drug+age, data=Data,ties="breslow")

time='time'
event='censor'

path <- "src/data/"

for (i in dir(path)) {
    load(file = paste0(path,i))
}
datasets <- list(D1,D2,D3)
expl_vars <- c("drug", "age")
time_col <- c("time")
censor_col <- c("censor")
ties <- "breslow"

# First... #
client <- vtg::MockClient$new(datasets, pkgname = "vtg.coxph")
fit <- vtg.coxph::dcoxph(client, expl_vars, time_col, censor_col,
                         organizations_to_include = list(1,2))
