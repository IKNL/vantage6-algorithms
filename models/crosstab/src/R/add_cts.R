#' Aggregator function
#' Adds each local cross table to form a global cross tabulation.
#'
#' @param nodes list of node specific cross table
#' @param master list containing output from `init_formula` and
#' `variable_categories`.
#'
#' @return Global cross tabulation.
#'
#' @export
#'
add_cts <- function(nodes, master) Reduce("+", nodes)
