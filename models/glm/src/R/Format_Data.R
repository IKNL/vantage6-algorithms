#' assign types to all columns from the data-frame
#'
#' @param data dataframe
#' @param types containing the types to set to the columns
#'
#' @return formatted dataframe
#'
format_data <- function(data, types) {

    column_names = names(types)
    for(i in 1:length(types)) {
        column_name = column_names[i]
        specs = types[[i]]
        type_ = specs$type
        if (type_ == "numeric"){
            data[[column_name]] = as.numeric(data[[column_name]])
        }
        if (type_ == "factor"){
            data[[column_name]] = factor(data[[column_name]], levels=specs$levels)
        }
    }
    data
}