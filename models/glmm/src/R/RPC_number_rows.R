#'
#' Get number of rows without NA
#'
RPC_number_rows <- function(data, formula){
    vars <- all.vars(formula)
    return(sum(complete.cases(data[,vars])))
}