remove(list=ls(all.names = T))
library(vtg);library(survival);library(vtg.survdiff);

Data=ovarian
datasets = list(vtg.survdiff::D1, vtg.survdiff::D2, vtg.survdiff::D3)
f=Surv(futime, fustat) ~ rx
vars=all.vars(f)


client <- vtg::MockClient$new(datasets, pkgname = "vtg.survdiff")
fit <- vtg.survdiff::dsurvdiff(client, formula = f, timepoints = NULL)

# master=list(time=vars[1],time2=NA,
#             event=vars[2],strata=vars[3],
#             timepoints=timepoints)
#
# node_time=list(RPC_time(D1,master),
#                RPC_time(D2,master),
#                RPC_time(D3,master))
# master=serv_time(nodes = node_time,master=master)
#
# node_tab1=list(RPC_tab(D1,master,1),
#               RPC_tab(D2,master,1),
#               RPC_tab(D3,master,1))
#
# master1=serv_tab(nodes = node_tab1,master=master)
#
# node_tab2=list(RPC_tab(D1,master,2),
#               RPC_tab(D2,master,2),
#               RPC_tab(D3,master,2))
# master2=serv_tab(nodes = node_tab2,master=master)


master=list(master1,master2)













