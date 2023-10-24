#' @export
#'
RPC_statistic <- function(data, col, E){

    data <- na.omit(data[,col])
    # access correct rows & column...
    local.E <- E[dimnames(E)[[1]] %in% dimnames(data)[[1]],
                 dimnames(E)[[2]] %in% dimnames(data)[[2]]]
    return(sum((abs(data - local.E))^2/local.E))
}
