rm(list=ls(all.names = T)); set.seed(1234L)
library(vtg);library(dplyr);library(survival);library(foreign);
library(vtg.coxzph);library(survminer);library(vtg.coxph);library(splines)

tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

Data <- read.table("https://stats.idre.ucla.edu/stat/r/examples/asa/hmohiv.csv"
                   , sep=",", header = TRUE)
time='time';event='censor';
resid=TRUE
se=TRUE
df=4
num_pts=40
xlab="Time"
ylab=""
lty=1:2
col=1
lwd=1
transform='log'
data1 = read.csv("C://Users/hal2002.53340//Downloads//teststarter_n100_source1.csv")
data2 = read.csv("C://Users/hal2002.53340//Downloads//teststarter_n100_source0.csv")
datasets = list(data1, data2)

regfit <- coxph(Surv(time, censor)~age + site + hospital_id,
                data=rbind(data1, data2),ties="breslow")

Rzph <- cox.zph(regfit,transform = "identity")

# path <- "src/data/"
#
# for (i in dir(path)) {
#     load(file = paste0(path,i))
# }
# datasets <- list(D1,D2,D3)
expl_vars <- c("age", "site", "hospital_id")
time_col <- c("time")
censor_col <- c("censor")
ties <- "breslow"

# First... #
client <- vtg::MockClient$new(datasets, pkgname = "vtg.coxph")
fit <- vtg.coxph::dcoxph(client, expl_vars, time_col, censor_col, types = NULL)
fit = jsonlite::fromJSON("C://Users/hal2002.53340/Desktop/input_json_cox.json")
client <- vtg::MockClient$new(datasets, pkgname = "vtg.coxzph")
coxzph <- vtg.coxzph::dcoxzph(client, fit = fit, time = time, event = event,
                              transform = transform)
