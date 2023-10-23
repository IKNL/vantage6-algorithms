RPC_get_sums <- function(data, col)
{
    data = na.omit(data)
    ncol <- length(unique(col))
    if(ncol != length(col)) stop("You have repeated column names...")
    res <- c()
    if(ncol==2)
    {
        cat("Running chisq.test on 'X' and 'Y'...\n")
        x <- as.vector(data[, col[1]])
        dnameX <- deparse(substitute(x))
        xname <- ifelse(length(dnameX) > 1L || nchar(dnameX, "w")>30, "",
                        dnameX)
        y <- as.vector(data[, col[2]])
        dnameY <- deparse(substitute(y))
        yname <- ifelse(length(dnameY) > 1L || nchar(dnameY, "w")>30, "",
                        dnameY)
        OK <- complete.cases(x,y)
        x <- factor(x[OK])
        y <- factor(y[OK])
        if((nlevels(x) < 2L) || (nlevels(y) < 2L))
            stop("'x' & 'y' must have at least 2 levels \n")
        tab <- table(x, y)
        names(dimnames(tab)) <- c(xname, yname)
        dname <- paste(paste(dnameX, collapse = "\n"), "and",
                       paste(dnameY, collapse = "\n"))
        n <- sum(tab)
        nr <- as.integer(nrow(tab))
        nc <- as.integer(ncol(tab))
        sr <- as.integer(rowSums(tab))
        sc <- as.integer(colSums(tab))


    }
    else
    {
        if(is.data.frame(data[,col])){
            cat("Running chisq.test on dataframe... \n")
            dt <- as.matrix(data[,col])
            n <- sum(dt)
            nr <- as.integer(nrow(dt))
            nc <- as.integer(ncol(dt))
            sr <- rowSums(dt)
            sc <- colSums(dt)

        }else{
            cat("Running chisq.test on single column... \n")
            dt <- as.vector(data[,col])
            n <- sum(dt)
            nr <- NULL
            nc <- NULL
            sr <- NULL
            sc <- NULL
        }
    }
    return(list("n" = n, "nr" = nr, "nc" = nc, "sr" = sr, "sc" = sc))
}
