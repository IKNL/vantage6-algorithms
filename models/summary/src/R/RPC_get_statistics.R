#' Get Node Statistics
#'
#' This function calculates all the preliminairy statistics used in the summary
#' algorithm. It calculates number of NA or missing data, length of each column
#' in the data, sum per column of data given that the data is not a factor,
#' and the range per column of the data:- if the column is a factor
#' then it returns a table of values with a disclosure check, otherwise
#' it simply returns the min and max values. Finally this also returns the
#' number of useable rows in the data.
#'
#' @param data Dataset
#' @param col Should be supplied by researcher as a vector of strings
#' representing the column names they think is present in the data
#' @param threshold for disclosure check. Default is 5.
#'
#' @return a list of na, lengths, sums, range and useable rows
#'
RPC_get_statistics <- function(data, col, threshold=5L, types=NULL){

    # Assign types
    if(!is.null(types)) data <- vtg.summary::assign_types(data, types)
    # NA's
    data.na <- check.na.data(data, col)
    # LENGTHS
    data.lengths <- check.lengths.data(data, col, threshold)
    # SUMMATION
    data.sums <- summation(data, col, data.lengths)
    # RANGE
    data.range <- range.fn(data, col, data.lengths, threshold)
    # USEABLE ROWS
    data.useable.rows <- useable.rows.data(data, col, threshold)

    return(
        list("data.na" = data.na,
             "data.lengths" = data.lengths,
             "data.sums" = data.sums,
             "data.range" = data.range,
             "data.useable.rows" = data.useable.rows
             )
           )
}

# this functionality is used repeatidly...
check.unique.columns.in.data <- function(data, col){
    uniq.col <- unique(col)
    cols.in.data <- uniq.col[uniq.col %in% names(data)]
    return(cols.in.data)
}

check.na.data <- function(data, col){
    cols.in.data <- check.unique.columns.in.data(data, col)
    # to find how many NA in each column
    na.of.columns <- lapply(cols.in.data, function(colName){
        if(any(is.na(data[,colName]))){
            len.na <- length(which(is.na(data[,colName])))
        }else{
            len.na <- 0
        }
        names(len.na) <- colName
        return(len.na)
    })
    # it's much simpler and cleaner to return a named vector
    return(Reduce("c", na.of.columns))
}

check.lengths.data <- function(data, col, threshold){
    cols.in.data <- check.unique.columns.in.data(data, col)
    length.of.columns <- lapply(cols.in.data, function(colName){
        len.data <- length(na.omit(data[,colName]))
        names(len.data) <- colName
        return(len.data)
    })
    length.of.columns <- lapply(length.of.columns, function(col.len){
        if((col.len == 0) || (col.len > threshold)){
            len.data <- col.len
        }else if(col.len < threshold){
            stop("Disclosure risk, not enough observations in ", colName, " < "
                 , threshold)
        }
    })
    # it's much simpler and cleaner to return a named vector
    return(Reduce("c", length.of.columns))
}

summation <- function(data, col, data.lengths){
    cols.in.data <- check.unique.columns.in.data(data, col)
    sums.per.column <- lapply(cols.in.data, function(colName){
        # first we check if the length of the data is 0, if so sum will be 0
        if(data.lengths[colName] == 0){
            sum.per.col <- 0
        }else if(is.factor(data[,colName])){
            sum.per.col <- NaN
        }else if(is.numeric(data[,colName])){
            sum.per.col <- sum(data[,colName], na.rm = T)
        }else{
            stop("Data has to be in the form of a data frame and has to be
                 a numerical value...")
        }
        names(sum.per.col) <- colName
        return(sum.per.col)
    })
    return(Reduce("c", sums.per.column))
}

# we don't want to run on small tabular data due to disclosive risk
disclosure.check.tab <- function(tab, threshold=5L){
    if(any(tab < threshold)){
        stop(paste0("Disclosure risk, some values in '", colName,
                    "' are lower than ", threshold))
    }else{
        tab
    }
}

range.fn <- function(data, col, data.lengths, threshold=5L){
    cols.in.data <- check.unique.columns.in.data(data, col)
    range.per.column <- lapply(cols.in.data, function(colName){
        dt <- na.omit(data[,colName])
        if(data.lengths[colName] == 0){
             NULL
        }else if(is.factor(dt)){
            disclosure.check.tab(table(dt), threshold)
        }else{
            range(dt)
        }
    })
    names(range.per.column) <- cols.in.data
    return(range.per.column)
}

# Different function to lengths because this tells you as a whole,
# how many useable rows are there in the dataset.
useable.rows.data <- function(data, col, threshold=5L){
    cols.in.data <- check.unique.columns.in.data(data, col)
    dt <- na.omit(data[,cols.in.data])
    # if dt is simply a vector...
    n.useable.rows <- if(is.null(dim(data))){
        length(dt)
    }else{
        nrow(dt)
    }
    if(is.null(n.useable.rows) || n.useable.rows == 0){
        return(0)
    }else if(n.useable.rows > threshold){
        return(n.useable.rows)
    }else{
        stop("Disclosure risk as there are fewer than ",
             threshold, " observations.")
    }
}
