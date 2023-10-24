#' @export
#'
RPC_get_sums <- function(data, col){
    data = na.omit(data[,col])
    ncol <- length(unique(col))
    if(ncol != length(col)) stop("You have repeated column names...")
    res <- c()
    if(ncol==2){
        cat("Running chisq.test on 'X' and 'Y'...")
        x <- as.vector(data[,1])
        dnameX <- deparse(substitute(x))
        y <- as.vector(data[,2])
        dnameY <- deparse(substitute(y))
        OK <- complete.cases(x,y)
        x <- factor(x[OK])
        y <- factor(y[OK])
        if((nlevels(x) < 2L) || (nlevels(y) < 2L))
            stop("'x' & 'y' must have at least 2 levels")
        tab <- stats::table(x, y)
        names(dimnames(tab)) <- c(dnameX, dnameY)
        n <- sum(tab)
        nr <- as.integer(nrow(tab))
        nc <- as.integer(ncol(tab))
        sr <- rowSums(tab)
        sc <- colSums(tab)
    }else{
        if(is.data.frame(data)){
            cat("Running chisq.test on dataframe...")
            dt <- as.matrix(data)
            n <- sum(dt)
            nr <- as.integer(nrow(dt))
            nc <- as.integer(ncol(dt))
            sr <- rowSums(dt)
            sc <- colSums(dt)

        }else{
            cat("Running chisq.test on single column...")
            dt <- as.vector(data)
            n <- sum(dt)
            nr <- NULL
            nc <- NULL
            sr <- NULL
            sc <- NULL
        }
    }
    return(list("n" = n, "nr" = nr, "nc" = nc, "sr" = sr, "sc" = sc))
}
