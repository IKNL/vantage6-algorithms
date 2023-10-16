#' Return a dataframe of unique event times
#'
#' Params:
#'   df: dataframe
#'   time_col: name of the column that contains the event/censor times
#'
#' Return:
#'   dataframe with columns time and Freq
RPC_get_unique_event_times_and_counts <- function(df, time_col, censor_col,
                                                  types=NULL){

    # Specify data types for the columns in the data
    if (!is.null(types)) df <- assign_types(df, types)

    time <- df[df[, censor_col]==1, time_col]
    time <- sort(time)

    df_time <- as.data.frame(table(time), stringsAsFactors=F)
    df_time <- apply(df_time, 2, as.numeric)
    return(df_time)
}


