RPC_get_NA <- function(data, col){
    # All this function has to do is collect how many missing values
    # there are in the data...

    Nas <- list()

    for(column in col){
        if(any(is.na(data[,column]))){
            na.pos <- which(is.na(data[,column]))
            Nas[[column]] <- length(na.pos)
        }

    }
    return(Nas)
}
