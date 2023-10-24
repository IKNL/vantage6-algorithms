dchisqtest <- function(client, col, probs = NULL)
{
    set.seed(123L)
    Data <- data.frame("X" = sample(1:10, size = 100, replace = T),
                       "Y"=sample(c(1:3, NA),size= 100, replace = T),
                       "Z"=sample(c(6:19, NA),size= 100, replace = T))

    d1 = Data[1:33,]
    d2 = Data[34:67,]
    d3 = Data[68:100,]

    datasets= list(d1, d2, d3)

    data = Data

    col= c("X", "Y", "Z")
    #########################

    node.lens <- lapply(datasets, RPC_get_N, col)

    # node.lens won't run unless all the class is the same...
    data.class <- attributes(node.lens[[1]])$class

    total.lengths <- sumlocals(node.lens)

    p <- assign_probabilities((N <- ifelse(data.class == "DF", total.lengths$y,
                                           total.lengths$x)), probs)

    node.sums <- lapply(datasets, RPC_get_sums, col)

    exp.and.var <- expectation(node.sums, p,
                               (is.col <- ifelse(data.class == "col", T, F)))

    E.glob <- exp.and.var$E

    V.glob <- exp.and.var$V

    node.statistic <- lapply(datasets, RPC_statistic, col, E.glob)

    glob.statistic <- Reduce(`+`, node.statistic)
}