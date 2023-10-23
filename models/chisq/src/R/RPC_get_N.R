RPC_get_N <- function(data, col)
{
    data = na.omit(data)
    ncol <- length(unique(col))
    if(ncol != length(col)) stop("You have repeated column names...")
    res <- c()
    if(ncol==2)
    {
        cat("Running chisq.test on 'X' and 'Y'...\n")
        x <- as.vector(data[, col[1]])
        y <- as.vector(data[, col[2]])
        OK <- complete.cases(x,y)
        x <- factor(x[OK])
        y <- factor(y[OK])
        if((nlevels(x) < 2L) || (nlevels(y) < 2L))
            stop("'x' & 'y' must have at least 2 levels")
        res <- c(length(x), length(y))
        attr(res, "class") <- c("2 by 2")
    }
    else
    {
        cat("Running chisq.test on dataframe... \n")
        if(is.data.frame(data[,col])){
            dt <- as.matrix(data[,col])
            res <- c(nrow(dt), ncol(dt))
            attr(res, "class") <- c("DF")
        }else{
            dt <- as.vector(data[,col])
            res <- c(length(dt))
            attr(res, "class") <- c("col")
        }
    }
    res
}
