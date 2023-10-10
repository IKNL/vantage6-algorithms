#' @export
#'
percentage <- function(output, node) node/rowSums(output)
