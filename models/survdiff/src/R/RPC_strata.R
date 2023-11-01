#' @export
#'
RPC_strata <- function(data, subset_rules, strata){
    
    # data pre-processing
    data <- extend_data(data)
    data <- subset_data(data, subset_rules)

    return(unique(data[,strata]))
}