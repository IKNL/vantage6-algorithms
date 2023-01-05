# Clear the environment completely
rm(list = ls(all.names = TRUE))

library(namespace)
library(vtg)
library(vtg.glmm)
library(foreign)
library(lme4)

tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

df1 = read.csv(paste0(getwd(), "/data/data1.csv"))[1:50,]
df2 = read.csv(paste0(getwd(), "/data/data2.csv"))

datasets <- list(df1, df2)
start = list(theta=0.1, fixef = c(0.1, 0.1,0.1,0.1,0.1))
f = awards ~ math+female+prog+(1|cid)
family = "poisson"
nAGQ = 20
client <- vtg::MockClient$new(datasets, pkgname='vtg.glmm')

################################
####### Mock Client Run ########
################################

glmm.mock <- function(datasets, start, local_eval, formula, family, nAGQ, ...) {
    client <- vtg::MockClient$new(datasets, pkgname='vtg.glmm')
    # client$set.task.image()
    results <- vtg.glmm::glmm(client, start, local_eval, formula=formula, family=family, nAGQ=nAGQ,...)
    return(results)
}

y = glmm.mock(datasets=datasets, start=list(theta=start$theta, fixef=start$fixef),
              local_eval = "localdev", formula = f,
              family = family, nAGQ = nAGQ)

packaged_result = vtg.glmm::as.GLMM(y, data= df1)

################################
###### Compare with GLMER ######
################################

df <- rbind(datasets[[1]], datasets[[2]])
df$cid = as.factor(df$cid)

xx <- suppressWarnings(glmer(formula = f, data = df, control = glmerControl(optimizer = "nlminbwrap", optCtrl = list(trace = 1)),
            start = list(theta=start$theta, fixef = start$fixef),
            family = family, nAGQ = nAGQ))

grad = xx@optinfo$derivs$gradient
hess = xx@optinfo$derivs$Hessian
var.covar = solve(0.5*hess)
