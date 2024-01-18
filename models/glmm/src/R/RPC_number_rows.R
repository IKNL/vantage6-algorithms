#'
#' Get number of rows without NA
#' @export
#'
RPC_number_rows <- function(data, formula){
    vars <- all.vars(formula)
    return(sum(complete.cases(data[,vars])))
}