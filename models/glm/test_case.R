data(user_1)

datasets <- list(
    read.csv("D:\\data\\glm\\goal3.csv"),
    read.csv("D:\\data\\glm\\iknl.csv"),
    read.csv("D:\\data\\glm\\xeltis.csv")
)

formula <- d~end+sex+agecat2+site2+country1+offset(log(y))
# formula <- d~end+agecat2+country1+offset(log(y))

glm.mock <- function(datasets, ...) {
    client <- vtg::MockClient$new(datasets, pkgname='vtg.glm')
    results <- vtg.glm::dglm(client, ...)
    return(results)
}
library(devtools)
go <- expression(install(dependencies = F, quick = T))
eval(go)
results_v6 <- glm.mock(
    datasets,
    formula=formula,
    dstar="d_star",
    types=list(
        sex=list(type='factor',levels=1:2, ref=NULL),
        site2=list(type='factor',levels=c(1,2,3,4,5,9), ref=NULL),
        end=list(type='factor',levels=1:5, ref=NULL),
        agecat2=list(type='factor',levels=1:5, ref='4'),
        country1=list(type='factor',levels=c(1,2,4), ref=NULL)
    ),
    family='rs.poi',
    maxit=25,
    tol= 1e-08
)
vtg.glm::as.GLM(results_v6)


#
#
#

a_local <- readRDS('D:\\data\\glm\\local_a')
b_local <- readRDS('D:\\data\\glm\\local_b')
local <- solve(a_local, b_local, tol = 2 * .Machine$double.eps)

a_docker <- readRDS('D:\\data\\glm\\docker_a')
b_docker <- readRDS('D:\\data\\glm\\docker_b')
docker <- solve(a_local, b_local, tol = 2 * .Machine$double.eps)


#
#
#

goal3=read.csv("D:\\data\\glm\\goal3.csv")
iknl=read.csv("D:\\data\\glm\\iknl.csv")
xeltis=read.csv("D:\\data\\glm\\xeltis.csv")

types=list(
    sex=list(type='factor',levels=1:2, ref=NULL),
    site2=list(type='factor',levels=c(1,2,3,4,5,9), ref=NULL),
    end=list(type='factor',levels=1:5, ref=NULL),
    agecat2=list(type='factor',levels=1:5, ref='4'),
    country1=list(type='factor',levels=c(1,2,4), ref=NULL)
)
family='rs.poi'
maxit=25
tol= 1e-08
formula <- d~end+agecat2+country1+offset(log(y))
dstar='d_star'
params <- list(formula = formula, types=types, dstar=dstar, family = family,
               iter = 1, tol = tol, maxit = maxit)
local_iknl_node_beta_1 <- vtg.glm::RPC_node_beta(iknl, master=params)
local_xeltis_node_beta_1 <- vtg.glm::RPC_node_beta(xeltis, master=params)
local_goal3_node_beta_1 <- vtg.glm::RPC_node_beta(goal3, master=params)

docker_iknl_node_beta_1 <- readRDS('D:\\data\\glm\\iknl_node_beta1')
docker_xeltis_node_beta_1 <- readRDS('D:\\data\\glm\\xeltis_node_beta1')
docker_goal3_node_beta_1 <- readRDS('D:\\data\\glm\\goal3_node_beta1')

#
#
#

types=list(
    sex=list(type='factor',levels=1:2, ref=NULL),
    site2=list(type='factor',levels=c(1,2,3,4,5,9), ref=NULL),
    end=list(type='factor',levels=1:5, ref=NULL),
    agecat2=list(type='factor',levels=1:5, ref='4'),
    country1=list(type='factor',levels=c(1,2,4), ref=NULL)
)
family='rs.poi'
maxit=25
tol= 1e-08
formula <- d~end+agecat2+country1+offset(log(y))
dstar='d_star'
params <- list(formula = formula, types=types, dstar=dstar, family = family,
               iter = 1, tol = tol, maxit = maxit)
weights=NULL
if(!is.null(params$types)){
    data <- vtg.glm::format_data(iknl, params$types)
}
formula <- params$formula
family <- params$family
dstar <- params$dstar
y <- eval(formula[[2]], envir = data)
saveRDS(y, 'D:\\data\\glm\\local-line11-y')
# Create a model matrix
X <- model.matrix(formula, data = data)
saveRDS(X, 'D:\\data\\glm\\local-line14-x')
# Extract the offset from formula (if exists)
offset <- model.offset(model.frame(formula, data = data))
saveRDS(offset, 'D:\\data\\glm\\local-line17-offset')
if (family == "rs.poi") dstar <- eval(as.name(dstar), data)
saveRDS(dstar, 'D:\\data\\glm\\local-line20-dstar')
family <- vtg.glm::get_family(family, dstar, data)
saveRDS(family, 'D:\\data\\glm\\local-line23-family')
if (is.null(weights)) weights <- rep.int(1, nrow(X))
saveRDS(family, 'D:\\data\\glm\\local-line26-weights')
if (is.null(offset)) offset <- rep.int(0, nrow(X))
saveRDS(family, 'D:\\data\\glm\\local-line28-weights')
nobs <- nrow(X)
saveRDS(nobs, 'D:\\data\\glm\\local-line31-nobs')
nvars <- ncol(X)
saveRDS(nvars, 'D:\\data\\glm\\local-line33-nvars')
etastart = NULL
mustart= pmax(y,dstar) + 0.1
saveRDS(mustart, 'D:\\data\\glm\\local-line37-mustart')
eta = family$linkfun(mustart)
saveRDS(eta, 'D:\\data\\glm\\local-line40-eta')
mu <-  family$linkinv(eta)
varg <- family$variance(mu)
gprime <- family$mu.eta(eta)
saveRDS(mu, 'D:\\data\\glm\\local-line43-mu')
saveRDS(varg, 'D:\\data\\glm\\local-line44-varg')
saveRDS(gprime, 'D:\\data\\glm\\local-line45-gprime')
z <- (eta - offset) + (y - mu) / gprime
# Update the weights
W <- weights * as.vector(gprime^2 / varg)
# Calculate the dispersion matrix
dispersion <- sum(W *((y - mu) / family$mu.eta(eta))^2)
saveRDS(z, 'D:\\data\\glm\\local-line50-z')
saveRDS(W, 'D:\\data\\glm\\local-line52-W')
saveRDS(dispersion, 'D:\\data\\glm\\local-line54-dispersion')
v1 = crossprod(X, W*X)
v2 = crossprod(X, W*z)
wt1 = sum(weights * y)
wt2 = sum(weights)
saveRDS(v1, 'D:\\data\\glm\\local-line60-v1')
saveRDS(v2, 'D:\\data\\glm\\local-line61-v2')
saveRDS(wt1, 'D:\\data\\glm\\local-line62-wt1')
saveRDS(wt2, 'D:\\data\\glm\\local-line63-wt2')
