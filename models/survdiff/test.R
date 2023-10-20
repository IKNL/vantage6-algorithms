remove(list=ls(all.names = T))
library(vtg);library(survival);library(vtg.survdiff);

Data=ovarian
datasets = list(vtg.survdiff::D1, vtg.survdiff::D2, vtg.survdiff::D3)
f=Surv(futime, fustat) ~ rx
vars=all.vars(f)
R=survdiff(f, Data)

client <- vtg::MockClient$new(datasets, pkgname = "vtg.survdiff")
fit <- vtg.survdiff::dsurvdiff(client,
                               formula = f,
                               timepoints = NULL)