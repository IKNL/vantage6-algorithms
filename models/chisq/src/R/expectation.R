#' @export
#'
expectation <- function(nodesums, p, is.col = F){

    if(!is.col){
        glob.n <- Reduce(`+`, lapply(nodesums, function(x) x$n))
        glob.nr <- Reduce(`+`, lapply(nodesums, function(x) x$nr))
        glob.nc <- Reduce(`+`, lapply(nodesums, function(x) x$nc))
        glob.sr <- Reduce(`c`, lapply(nodesums, function(x) x$sr))
        glob.sc <- Reduce(`+`, lapply(nodesums, function(x) x$sc))


        E = outer( glob.sr, glob.sc) / glob.n
        v <- function(r, c, n) c * r * (n - r) * (n - c)/n^3
        V <- outer(glob.sr, glob.sc, v, glob.n)
    }else{
        glob.n <- Reduce(`+`, lapply(nodesums, function(x) x$n))
        E <- glob.n * p
        V <- glob.n * p * (1-p)
    }
    return(list("E" = E , "V" = V))
}
