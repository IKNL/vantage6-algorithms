rm(list=ls(all.names = T))
library(vtg.coxph);library(dplyr);library(vtg);library(survival);
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

# Data <- read.table("https://stats.idre.ucla.edu/stat/r/examples/asa/hmohiv.csv"
                   # , sep=",", header = TRUE)

data1 = read.csv("C://Users//hal2002.53340//Downloads//teststarter_n100_source1.csv")
data2 = read.csv("C://Users//hal2002.53340//Downloads//teststarter_n100_source0.csv")
datasets = list(data1, data2)
Data = rbind(data1, data2)

regfit <-  coxph(Surv(time, censor)~age + site + hospital_id, data=Data,
                 ties="breslow")

time='time'
event='censor'

# path <- "src/data/"

# for (i in dir(path)) load(file = paste0(path,i))

# datasets <- list(vtg.coxph::D1,vtg.coxph::D2,vtg.coxph::D3)

expl_vars <- c("age", "site", "hospital_id")
time_col <- c("time")
censor_col <- c("censor")
ties <- "breslow"
types <- list(age = list(type = "numeric"),
              site = list( type = "factor", levels = c(5,6,7,8)),
              hospital_id = list(type = "factor", levels = c(1,2,3,4,5),
                                 ref=NULL))

# First... #
client <- vtg::MockClient$new(datasets, pkgname = "vtg.coxph")
fit <- vtg.coxph::dcoxph(client, expl_vars, time_col, censor_col,
                         types = NULL, organizations_to_include = NULL)
