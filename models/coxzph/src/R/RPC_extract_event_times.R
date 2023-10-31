#' RPC call for secondary step of Federated Coxzph, extract unique event times.
#' @param data dataframe containing the data, this is automatically supplied
#'    by the node
#' @param time this is a string detailing which column of the dataframe the
#'    algorithm should extract the time from
#' @param event this is a string detailing which column of the dataframe the
#'    algorithm should extract the event from
#' @return uniuqe event times
#'
RPC_extract_event_times <- function(data,subset_rules,time,event) {

    # data pre-processing
    data <- extend_data(data)
    data <- subset_data(data, subset_rules)
    
    vtg::log$debug("Extracting unique event times...")

    data <- data[order(data[,time]), ]
    unique_event_times <- unique(data[which(data[,event]==1),time])

    return(unique_event_times)
}
