RPC_shared_frailty <- function(data, beta, listArgs){

    library("mexhaz")
    # data <- listArgs$data
    f <- listArgs$formula
    base <- listArgs$base
    deg <- listArgs$degree
    knots <- listArgs$knots
    random <- listArgs$random
    # exp <- listArgs$expected

    suppressWarnings(iter1 <- mexhaz::mexhaz(formula=f, data=data, base=base, degree=deg,
                                     knots=knots, random=random,
                                     # expected=exp,
                                     mode="eval", init=beta))
    res <- iter1$loglik
    attr(res, "gradient") <- iter1$gradient
    attr(res, "hessian") <- iter1$hessian

    return(res)
}