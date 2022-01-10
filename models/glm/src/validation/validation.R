#' Validation of the GLM algorithm.
#' 
#' This script runs various GLM models with both the built-in R glm() function 
#' (centralized approach), and our federated implementation (federated 
#' approach).
#' 
#' The next families are supported by this script:
#'    gaussian(link = "identity"): gaussian regression
#'    binomial(link = "logit"): normal logistic regression
#'    poisson(link = "log"): poisson regression
#'    "rs.poi": custom glm relative survival model with poisson error
#'    
#' The validation() function compares these centralized and federated results. 
#' The validation results are printed to the console for multiple output 
#' variables. 'TRUE' means the centralized and federated results are the same.
#' 
#' The .csv files for the data can be found in: 
#'    iknl/vantage6-algorithms/models/glm/src/data.
#' 

validation <- function(FL_results_plain, central_results){
  
  central_results_summary <- summary.glm(central_results)
  FL_results <- vtg.glm::as.GLM(FL_results_plain)
  
  precision <- 10
  options(digits=precision)
  my_round <- function(x) {round(x, digits = 10)}
  
  validation_result <- list()
  
  #converged
  validation_result['converged'] = FL_results_plain$converged==central_results$converged
  
  #coefficients
  FL_coefs = sapply(FL_results_plain$coefficients, my_round, USE.NAMES = TRUE)
  central_coefs = sapply(central_results$coefficients, my_round, USE.NAMES = TRUE)
  validation_result['coefficients'] = list(FL_coefs==central_coefs)
  
  #std.error
  FL_stderr = sapply(FL_results_plain$Std.Error, my_round, USE.NAMES = TRUE)
  central_stderr = sapply(central_results_summary$coefficients[, 'Std. Error'], my_round, USE.NAMES = TRUE)
  validation_result['std.error'] = list(FL_stderr==central_stderr)
  

  if(central_results_summary$family$family %in% c('poisson', 'binomial')) {letter='z'} 
  else if(central_results_summary$family$family=='gaussian') {letter='t'}
  
  #pvalue
  FL_pval = sapply(FL_results_plain$pvalue, my_round, USE.NAMES = TRUE)
  central_pval = sapply(central_results_summary$coefficients[, sprintf("Pr(>|%s|)", letter)], my_round, USE.NAMES = TRUE)
  validation_result['pvalue'] = list(FL_pval==central_pval)
  
  #zvalue
  FL_zval = sapply(FL_results_plain$zvalue, my_round, USE.NAMES = TRUE)
  central_zval = sapply(central_results_summary$coefficients[, sprintf("%s value", letter)], my_round, USE.NAMES = TRUE)
  validation_result['zvalue'] = list(FL_zval==central_zval)
  
  #dispersion
  FL_dispersion = sapply(FL_results_plain$dispersion, my_round, USE.NAMES = TRUE)
  central_dispersion = sapply(central_results_summary$dispersion, my_round, USE.NAMES = TRUE)
  validation_result['dispersion'] = FL_dispersion==central_dispersion
  
  #formula
  validation_result['formula'] = FL_results_plain$formula==central_results$formula
  
  #family
  FL_family = jsonlite::toJSON(FL_results_plain$family, auto_unbox = TRUE, force = T)
  central_family = jsonlite::toJSON(central_results$family, auto_unbox = TRUE, force = T)
  validation_result['family'] = FL_family==central_family
  
  #deviance
  FL_deviance = sapply(FL_results_plain$deviance, my_round, USE.NAMES = TRUE)
  central_deviance = sapply(central_results$deviance, my_round, USE.NAMES = TRUE)
  validation_result['deviance'] = FL_deviance==central_deviance
  
  #null.deviance
  FL_nulldeviance = sapply(FL_results_plain$null.deviance, my_round, USE.NAMES = TRUE)
  central_nulldeviance = sapply(central_results$null.deviance, my_round, USE.NAMES = TRUE)
  validation_result['null.deviance'] = FL_nulldeviance==central_nulldeviance
  
  #dof
  FL_dof = sapply(FL_results$df.residual, my_round, USE.NAMES = TRUE)
  central_dof = sapply(central_results$df.residual, my_round, USE.NAMES = TRUE)
  validation_result['df.residual'] = FL_dof==central_dof
  
  #null.dof
  FL_null = sapply(FL_results$df.null, my_round, USE.NAMES = TRUE)
  central_null = sapply(central_results$df.null, my_round, USE.NAMES = TRUE)
  validation_result['df.null'] = FL_null==central_null
  
  #AIC
  FL_aic = sapply(FL_results$aic, my_round, USE.NAMES = TRUE)
  central_aic = sapply(central_results$aic, my_round, USE.NAMES = TRUE)
  validation_result['AIC'] = FL_aic==central_aic
  
  validation_result
}


## prepare data
datasets <- list(
  read.csv('../data/data_user1.csv'),
  read.csv('../data/data_user2.csv'),
  read.csv('../data/data_user3.csv')
)
datasets_combined <- do.call(rbind.data.frame, datasets)



## gaussian
print('gaussian validation')
central_results <- glm(data=datasets_combined, formula = num_awards ~ prog + math, family=gaussian(link = "identity"))

client <- vtg::MockClient$new(datasets, "vtg.glm")
FL_results_plain <- vtg.glm::dglm(client, formula = num_awards ~ prog + math, family=gaussian(link = "identity"), tol=1e-08, maxit=25)

val_gaus_res = validation(FL_results_plain, central_results)
print(val_gaus_res)

rm(central_results)
rm(FL_results_plain)



## poisson
print('poisson validation')
central_results <- glm(data=datasets_combined, formula = num_awards ~ prog + math, family=poisson(link = "log"))

client <- vtg::MockClient$new(datasets, "vtg.glm")
FL_results_plain <- vtg.glm::dglm(client, formula = num_awards ~ prog + math, family=poisson(link = "log"), tol=1e-08, maxit=25)

val_poisson_res = validation(FL_results_plain, central_results)
print(val_poisson_res)

rm(central_results)
rm(FL_results_plain)



## binomial
print('binomial')
central_results <- glm(data=datasets_combined, formula = num_awards_norm ~ prog + math, family=binomial(link = "logit"))

client <- vtg::MockClient$new(datasets, "vtg.glm")
FL_results_plain <- vtg.glm::dglm(client, formula = num_awards_norm ~ prog + math, family=binomial(link = "logit"), tol=1e-08, maxit=25)

val_binomial_res = validation(FL_results_plain, central_results)
print(val_binomial_res)



## rs.poi
print('rs.poi')
modperiod.link <- function(dstar) {
  structure(
    list(
      # Link
      linkfun = function(mu) {log(mu - dstar)} ,
      # Inverse link
      linkinv = function(eta) {exp(eta) + dstar} ,
      # Derivative of the inverse link (d_mu/d_eta)
      mu.eta = function(eta) {exp(eta)},
      # Functions for domain checking
      valideta = function(eta) TRUE,
      validmu = function(mu) mu > dstar ,
      #validmu = function(mu) all(is.finite(mu)) && all(mu > 0),
      name = "modperiod.link"
    ),
    class = "link-glm"
  )
}
format_data <- function(data, types) {
  
  column_names = names(types)
  for(i in 1:length(types)) {
    column_name = column_names[i]
    specs = types[[i]]
    type_ = specs$type
    if (type_ == "numeric"){
      data[[column_name]] = as.numeric(data[[column_name]])
    }
    if (type_ == "factor"){
      data = data[data[[column_name]] %in% specs$levels,]
      data[[column_name]] = factor(data[[column_name]], levels=specs$levels)
      if(! is.null(specs$ref)) data[[column_name]] = relevel(data[[column_name]], ref=specs$ref)
    }
  }
  data
}
types=list(prog=list(type='factor',levels=c('Vocational', 'General', 'Academic'), ref=NULL))
data <- format_data(datasets_combined, types)
mustart = pmax(data$num_awards, data$num_awards_norm) + 0.1

central_results <- glm(data=data, formula=num_awards ~ prog + math, family = poisson(link = modperiod.link(data$num_awards_norm)), mustart=mustart)

client <- vtg::MockClient$new(datasets, "vtg.glm")
FL_results_plain <- vtg.glm::dglm(client, formula=num_awards ~ prog + math, types=types, family='rs.poi', dstar="num_awards_norm", tol=1e-08, maxit=25)

val_customglm_res = validation(FL_results_plain, central_results)
print(val_customglm_res)
rm(central_results)
rm(FL_results_plain)
