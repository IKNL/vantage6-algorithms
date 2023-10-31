#' version: 1.0
#' Data filter function.
#'
#' This function will be called at the start of the analysis, and executed on 
#' the data of every node. Has to be implemented in every RPC call.
#'
#' @param data Data provided by client.
#' @param subset_rules A list of subset rules given by the user. When providing 
#' multiple subsetting steps the subsets will be executed in the order as given 
#' in the list. 
#' 
#' Example of a subset rules json file:
#' [
#'  {
#'    "subset": "site==6"
#'  },
#'  {
#'    "subset": "site %in% c(6,7)"
#'  },
#'  {
#'    "subset": "age>30 & age<=70"
#'  }
#' ]
#'
#' @return Either, the subsetted data to be used in the rest of the analysis, 
#' or, for privacy preserving reasons, an empty dataframe (with the column 
#' names) if the subsetted data has less than N rows.
#'
#' @export

subset_data <- function(data, subset_rules){

  library(dplyr)
  N = 5

  result <- data

  vtg::log$info(sprintf("This is subset_data"))
  print('Number of rows before subset_data:') 
  print(nrow(result))

  # no subset rules are given
  if(is.null(subset_rules)){
    print('Number of rows after subset_data:') 
    print(nrow(result))
    return(result)
  }
  
  # subset rules are given and data is subsetted
  for(n_rule in 1:nrow(subset_rules)){
    query <- subset_rules[n_rule, 'subset']
    result <- result %>% filter(!!rlang::parse_expr(query))
  }
  
  # subset rules are given and subsetted data is < N
  if(nrow(result)<N){
    warning(paste('This subset contains less than',N,'rows and will not be 
    returned for privacy preserving reasons.'))
    result <- NULL
  }

  print('Number of rows after subset_data:') 
  print(nrow(result))

  return(result)
}