#' @export
#'
sumlocals <- function(nodes){
    check = attributes(nodes[[1]])$class
    if(!all(sapply(nodes, function(x) attributes(x)$class) == check)){
        stop("Cannot find length of mixed inputs...")
    }
    x <- Reduce(`+`, sapply(nodes, function(x) x[1]))
    y <- ifelse(check == "DF",
                Reduce("all", sapply(nodes, function(x) x[2])),
                Reduce(`+`, sapply(nodes, function(x) x[2])))
    sumlocals <- if(check == "DF"){
        list("x" = x, "y" = nodes[[1]][2][y])
    }else if(check == "col"){
        list("x" = x)
    }else{
        list("x" = x, "y" = y)
    }
    return(sumlocals)
}
