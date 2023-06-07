#' Run the distributed CoxPH algorithm locally
#'
#' Splits the provided data frame in `splits` equal parts and runs
#' `dcoxph()`.
#'
#' Params:
#'   df: data frame containing the *full* dataset
#'   expl_vars: list of explanatory variables (covariates) to use
#'   time_col: name of the column that contains the event/censor times
#'   censor_col: name of the colunm that explains whether an event occured or
#'               the patient was censored
#'   splits: number of parts to split the data set in
#'
#' Return:
#'   data.frame with beta, p-value and confidence interval for each explanatory
#'   variable.
dcoxph.mock <- function(df, input_data, splits=5) {

    datasets <- list()

    for (k in 1:splits) {
        datasets[[k]] <- df[seq(k, nrow(df), by=splits), ]
    }

    client <- vtg::MockClient$new(datasets, pkgname=getPackageName())
    results <- dcoxph(client, input_data)
    return(results)
}

