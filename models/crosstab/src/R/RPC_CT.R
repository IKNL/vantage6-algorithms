#' Data station/ node side function.
#'
#' Calculates the local instance of the Cross tabulation.
#'
#' @param data Data provided by client.
#' @param master This will contain output from `init_formula`, a formula.
#'
#' @return Local instance of Cross tabulation. This computes the instances per
#' var_cat which belong to the data. In other words, frequency distribution
#' per categorical variable.
#'
#' @export
#'
RPC_CT <- function(data, master){
    for (i in all.vars(master$formula)) {
        data[,i] = factor(data[,i],levels = master$var_cat[[i]])
    }
    ct=xtabs(master$formula, data = data)
    return(ct)
}