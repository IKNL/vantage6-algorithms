#' Aggregator function
#'
#' Returns formula in a list
#'
#' @param f an object of class formula or one that can be converted.
#'
#' @return list with formula.
#'
#' @export
#'
init_formula <- function(f) list(formula = as.formula(f))