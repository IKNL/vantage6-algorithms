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

# df <- read.dta("https://stats.idre.ucla.edu/stat/data/hsbdemo.dta")
# df$cid = factor(df$cid)
###############################
######### For Checking ########
###############################

df1 = read.csv("C:/Users/hal2002.53340/Repositories/playground/testing-stats-functions/glmm/data1.csv")[1:50,]
df2 = read.csv("C:/Users/hal2002.53340/Repositories/playground/testing-stats-functions/glmm/data2.csv")

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

packaged_result = as.GLMM(y, data= df1)

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

iter1@resp$family

################################
########## Let's see ###########
################################

get_details <- function(){
    family <- get("family", env)
    nobs <- get("nobs", env)
    formula <- get("formula", env)
    nAGQ <-get("nAGQ", env)

}

get.dev <- function(start){
    len.start = length(start)
    theta = start[1]
    beta = start[2:len.start]
    suppressWarnings(iter1 <- glmer(formula = awards ~ math+(1|cid), data = df,
                                    family = poisson(link="log"), nAGQ = 10,
                                    control = glmerControl(
                                        optimizer = "nlminbwrap",
                                        optCtrl = list(maxfun=1)
                                    ),
                                    start = list(fixef = beta, theta=theta)))
    res <- iter1@devcomp$cmp["dev"]
    attr(res, "gradient") <- iter1@optinfo$derivs$gradient
    attr(res,"hessian") <- iter1@optinfo$derivs$Hessian
    attr(res, "family") <- iter1@resp$family
    attr(res, "theta") <- iter1@theta
    attr(res, "beta") <- iter1@beta

    return(res)
}

min.dev <- nlm(f = get.dev, p = c(0.1,0.1,0.1), hessian = T, gradtol = 1e-8, iterlim = 10000, check.analyticals = T)
nlminb(start = c(0.1,0.1,0.1), objective = get.dev)


########################
### Try with my glmm ###
########################

f.glmm.mod <- glFormula(formula = as.formula(y$formula), data = datasets[[1]], family = poisson(link="log")
                        , start = list(fixef=as.vector(y$fixed_effects), theta=as.numeric(y$random_effect))
                        , control = glmerControl(optimizer="nlminbwrap", optCtrl=list(maxfun=1))
                        )
                        # control = lmerControl(optimizer="nlminbwrap", optCtrl=list(maxfun=1)), start = list(fixef=as.vector(y$fixed_effects), theta=as.numeric(y$random_effect)))

dev <- do.call(mkGlmerDevfun, f.glmm.mod)

opt <- suppressWarnings(
    optimizeGlmer(
        devfun = dev,
        optimizer = "nlminbwrap",
        # stage = 0,
        verbose = T,
        start = list(
            fixef=as.vector(y$fixed_effects),
            theta=as.numeric(y$random_effect)
        )
        , control = glmerControl(optCtrl = list(maxfun = 0), use.last.params = T, optimizer = "nlminbwrap", boundary.tol = T, calc.derivs = T, nAGQ0initStep = T)
        )
    )

new.dev <- updateGlmerDevfun(devfun = dev, reTrms = f.glmm.mod$reTrms)


new.opt <- suppressWarnings(optimizeGlmer(devfun = new.dev, optimizer = "nlminbwrap", stage = 2,
                         control = glmerControl(optCtrl = list(maxfun = 1), use.last.params = T, optimizer = "nlminbwrap", boundary.tol = T, calc.derivs = T, nAGQ0initStep = T)))
