#' Data station / node side function.
#'
#' This function extracts from the data based on the formula provided the
#' unique levels/categories/factors.
#'
#' @param data Data provided by client.
#' @param subset_rules Set of filters for subsetting the data.
#' @param master output from `init_formula`, a formula.
#'
#' @return returns a list with unique categories/factors of the variable in
#' the data.
#'
#' @export
#'
RPC_get_vars <- function(data, subset_rules, master){

    data <- extend_data(data)
    data <- subset_data(data, subset_rules)

    f <- master$formula
    return(apply(data[,all.vars(f)], 2, unique))
}