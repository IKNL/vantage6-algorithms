#' @export
collect_ME <- function(re, fe){
    # function to collect from each node the correct number of random and fixed
    invisible(list("N_re"=length(re), "N_fe"=length(fe)))
}