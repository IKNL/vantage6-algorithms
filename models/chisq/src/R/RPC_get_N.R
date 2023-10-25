#' @export
#'
RPC_get_N <- function(data, col, threshold = 5L){
    if(!is.null(threshold)){
        if(!is.integer(threshold)){
            stop(paste0(threshold, " is not an Integer, try using: ", threshold
                        , "L"))
        }
        if(threshold < 0L){
            stop(paste0(threshold, " is negative..."))
        }
        if(is.infinite(threshold)){
            stop(paste0(threshold, " is infinite..."))
        }
    }else{
        stop("Threshold cannot be NULL...")
    }

    checker.fn <- function(x) mapply(FUN=function(i) length(x[x == i]),
                                     unique(x))

    data = na.omit(data[,col])
    ncol <- length(unique(col))
    if(ncol != length(col)) stop("You have repeated column names...")
    res <- c()
    if(ncol==2){
        cat("Running chisq.test on 'X' and 'Y'...\n")
        x <- as.vector(data[,1])
        y <- as.vector(data[,2])

        if((any(checker.fn(x)) < threshold) || (any(checker.fn(y)) < threshold))
        {
            stop(paste0("Disclosure risk, some values are lower than ",
                        threshold))
        }

        OK <- complete.cases(x,y)
        x <- factor(x[OK])
        y <- factor(y[OK])

        if((nlevels(x) < 2L) || (nlevels(y) < 2L))
            stop("'x' & 'y' must have at least 2 levels")
        res <- c(length(x), length(y))
        attr(res, "class") <- c("2 by 2")
    }else{
        cat("Running chisq.test on dataframe... \n")
        if(is.data.frame(data)){
            dt <- as.matrix(data)
            check <- lapply(1:ncol(dt), function(col_index) {
                uni.vals <- unique(dt[, col_index])
                occurrences <- sapply(uni.vals, function(uni_val) {
                    sum(dt[, col_index] == uni_val)
                })
                data.frame(uni.vals = uni.vals, count = occurrences)
            })

            disc.check <- Reduce("all", lapply(check, function(x) any(x$count < threshold)))
            if(disc.check){
                stop(paste0("Disclosure risk, some cells are lower than ",
                            threshold))
            }
            res <- c(nrow(dt), ncol(dt))
            attr(res, "class") <- c("DF")
        }else{
            dt <- as.vector(data)
            if(any(checker.fn(dt)) < threshold){
                stop(paste0("Disclosure risk, some values are lower than ",
                            threshold))
            }

            res <- c(length(dt))
            attr(res, "class") <- c("col")
        }
    }
    res
}
