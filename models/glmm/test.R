# Clear the environment completely
rm(list = ls(all.names = TRUE))
devtools::load_all("./src")

library(foreign)
library(lme4)

data <- lme4::cbpp
data$obs = 1:nrow(data)

datasets <-
    list(
        df1 =data[data$herd%in% c(1:5),],
        df2 =data[data$herd%in% c(6:10),],
        df3 =data[data$herd%in% c(11:15),]
    )
params = list(ranef=c(0.1), fixef = c(0.1,0.1,0.1,0.1,0.1))
formula = formula(incidence ~ size + period + (1|herd))
family = "poisson"
nAGQ = 20
local_eval = "localdev"

################################
####### Mock Client Run ########
################################

glmm.mock <- function(datasets, params, local_eval, formula, family, nAGQ) {
    client <- vtg::MockClient$new(datasets, pkgname='vtg.glmm')
    results <- vtg.glmm::glmm(client=client, params=params,
                              local_eval=local_eval, formula=formula,
                              family=family, nAGQ=nAGQ)
    return(results)
}

y = glmm.mock(datasets = datasets, params = params ,local_eval = local_eval,
              formula = formula,family = family, nAGQ = nAGQ)

packaged_result = vtg.glmm::as.GLMM(y, data=datasets$df1)

################################
###### Compare with GLMER ######
################################


(gm1 <- glmer(formula = formula, data = data, family = "poisson", nAGQ = nAGQ,
              verbose = 2))


(adap1 <- mixed_model(fixed =  cbind(incidence, size - incidence) ~ period,
                      random = ~ 1|herd, data=cbpp, family=binomial,
                      control=list("nAGQ" = 20)))


df <- rbind(datasets[[1]], datasets[[2]])
df$cid = as.factor(df$cid)

glmer_ans <- suppressWarnings(glmer(formula = f, data = df, control = glmerControl(optimizer = "nlminbwrap", optCtrl = list(trace = 1)),
            start = list(theta=start$theta, fixef = start$fixef),
            family = family, nAGQ = nAGQ))

grad = glmer_ans@optinfo$derivs$gradient
hess = glmer_ans@optinfo$derivs$Hessian
var.covar = solve(0.5*hess)
