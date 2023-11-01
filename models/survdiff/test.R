remove(list=ls(all.names = T))
library(vtg);library(survival);library(vtg.survdiff);

Data=ovarian
datasets = list(vtg.survdiff::D1, vtg.survdiff::D2, vtg.survdiff::D3)
f=Surv(futime, fustat) ~ rx
vars=all.vars(f)

Data[Data[,"futime"]>tmax ,"fustat"]=0
Data[Data[,"futime"]>tmax ,"futime"]=tmax
R=survdiff(f, Data)
tmax=430

client <- vtg::MockClient$new(datasets, pkgname = "vtg.survdiff")
fit <- vtg.survdiff::dsurvdiff(client,
                               formula = f,
                               tmax=tmax,
                               timepoints = NULL)
