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

load("src/data/df1.rda")
# load("src/data/df2.rda")

# datasets <- list(df1, df2)
datasets <-
    list(
        df1 =cbpp[cbpp$herd%in% c(1:5),],
        df2 =cbpp[cbpp$herd%in% c(6:10),],
        df3 =cbpp[cbpp$herd%in% c(11:15),]
    )
start = list(theta=0.1, fixef = c(0.1, 0.1,0.1,0.1))
# f = awards ~ math+female+prog+(1|cid)
f = formula(cbind(incidence, size - incidence) ~ period + (1 | herd))
family = "binomial"
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

packaged_result = vtg.glmm::as.GLMM(y, data=datasets$df1)

################################
###### Compare with GLMER ######
################################


(gm1 <- glmer(cbind(incidence, size - incidence) ~ period + (1 | herd),
              data = cbpp, family = binomial, nAGQ = 20, verbose = 2))


(adap1 <- mixed_model(fixed =  cbind(incidence, size - incidence) ~ period, random = ~ 1|herd, data=cbpp, family=binomial, control=list("nAGQ" = 20)))


df <- rbind(datasets[[1]], datasets[[2]])
df$cid = as.factor(df$cid)

glmer_ans <- suppressWarnings(glmer(formula = f, data = df, control = glmerControl(optimizer = "nlminbwrap", optCtrl = list(trace = 1)),
            start = list(theta=start$theta, fixef = start$fixef),
            family = family, nAGQ = nAGQ))

grad = glmer_ans@optinfo$derivs$gradient
hess = glmer_ans@optinfo$derivs$Hessian
var.covar = solve(0.5*hess)
