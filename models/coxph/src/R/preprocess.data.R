#' Split the dataframe column wise into covariate, censor and time columns.
preprocess.data <- function(df, expl_vars, censor_col, time_col) {
    # Sort the dataframe/matrix by time
    df[, time_col] = as.numeric(df[, time_col])
    sort_idx <- order(df[, time_col])
    df <- df[sort_idx, ]

    # Split dataframe into explanatory variables, time and censor columns
    Z <- df[, expl_vars]
    time <- df[, time_col]
    censor <- df[, censor_col]

    if (dim(as.matrix(Z))[2] == 1) {
        Z = as.matrix(Z)
    }

    # Return the list (dict)
    return(list(
        Z=Z,
        time=time,
        censor=censor
    ))
}

