#' @export
#'
assign_probabilities <- function(N, probs = NULL){
    if(is.null(probs)){
        return(rep(1/as.numeric(N) , as.numeric(N)))
    }else{
        return(probs)
    }
}

