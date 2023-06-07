#' Convert a list of rows into a dataframe
list.to.matrix <- function(l) {
    # sapply applies c() to the list and returns a matrix.
    # The matrix is then transposed
    return(t(sapply(l, c)))
}

