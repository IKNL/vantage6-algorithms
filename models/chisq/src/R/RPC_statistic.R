RPC_statistic <- function(data, col, E)
{
    data = na.omit(data)
    return(sum( (data[, col] - E)^2 / E ))
}
