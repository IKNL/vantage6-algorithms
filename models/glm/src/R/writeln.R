#' Write a string to STDOUT without the standard '[1]' prefix.
#'
#' @param ... Strings to write to STDOUT
#' @param sep Separator to use between strings. Defaults to a single space
#' @export
#' @examples
#' writeln("Hello, world!")
writeln <- function(..., sep=" ") {
    cat(paste(paste(..., collapse=sep), "\n"))
}

