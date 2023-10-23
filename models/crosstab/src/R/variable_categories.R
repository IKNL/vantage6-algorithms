#' Aggregator side function.
#'
#' Collect all the local instances of unique variables and sort them to a
#' global list of unique categories.
#'
#' @param nodes This contains the categories from each node. It is a list.
#' @param master List containing output from `init_formula`. Formula.
#'
#' @return Returns the master object with appended item, var_cat which is
#' the global unique categories.
#'
#' @export
#'
variable_categories <- function(nodes, master){
    categories <- sapply(all.vars(master$formula), function(i){
        unique(as.vector(sapply(nodes, function(j) j[[i]])))
    }, simplify=F)
    master$var_cat <- categories
    return(master)
}