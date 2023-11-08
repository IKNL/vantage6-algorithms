#' Federated Summary algorithm.
#'
#' This version has built in `threshold` parameter that checks if any counts
#' are less than tolerance. Default is 5. Can go lower (to 1). Up to data-owner.
#' @param client vtg::Client instance provided by node (datastation).
#' @param col Can by single column name or N column name.
#' @param threshold Disclosure check. Default is 5, if number of counts in
#' any cell is less than `threshold` the function stops and returns an error
#' message.
#' @param types types to subset data with.
#'
#' @return a list of combined summary statistics aggregated about all
#' datastation(s) in the study. It will return  a list containing the
#' following:
#' `global.nas` representing each unique column's number of missing values,
#' `global.lengths` representing total length of each column across each site,
#' `global.range` a list of ranges per column,
#' `global.means` a vector of means per column,
#' `global.variance` a vector of variance per column,
#' `node.specific.useable.rows` the node specific useable rows if the entire
#' data were used without missing values,
#' `global.useable.rows` is an aggregation of the node.specific.useable.rows.
#'
#' @author Hasan Alradhi
#' @author Matteo Cellamare
#' @author Frank Martin
#'
#' @export
#'
dsummary <- function(client, col, threshold = 5L, types = NULL,
                   organizations_to_include = NULL){

    log <- lgr::get_logger_glue("summary")
    log$set_threshold("debug")

    image.name <- "harbor2.vantage6.ai/starter/summary:latest"

    client$set.task.image(
        image.name,
        task.name="summary"
    )

    # Update the client organizations according to those specified
    if (!is.null(organizations_to_include)) {

        vtg::log$info("Sending tasks only to specified organizations")
        organisations_in_collaboration = client$collaboration$organizations
        # Clear the current list of organisations in the collaboration
        # Will remove them for current task, not from actual collaboration
        client$collaboration$organizations <- list()
        # Reshape list when the organizations_to_include is not already a list
        # Relevant when e.g., Python is used as client
        if (!is.list(organizations_to_include)){
            organisations_to_use <- toString(organizations_to_include)

            # Remove leading and trailing spaces as in python list
            organisations_to_use <-
                gsub(" ", "", organisations_to_use, fixed=TRUE)

            # Convert to list assuming it is comma separated
            organisations_to_use <-
                as.list(strsplit(organisations_to_use, ",")[[1]])
        }
        # Loop through the organisation ids in the collaboration
        for (organisation in organisations_in_collaboration) {
            # Include the organisations only when desired
            if (organisation$id %in% organisations_to_use) {
                client$collaboration$organizations[[length(
                    client$collaboration$organizations)+1]] <- organisation
            }
        }
    }

    if (client$use.master.container) {
        log$info("Running `dsummary` in master container using
                                  image '{image.name}'..")
        result <- client$call(
            "dsummary",
            col = col,
            threshold = threshold
        )
        return(result)
    }

    log$info("Computing Summary. Warning: If your data is factor calculations
             such as sum, mean, squared-deviance and variance are not
             applicable.")

    log$info("Computing initial statistics...")
    initial.statistics <- client$call(
        "get_statistics",
        col = col,
        threshold = threshold,
        types = types
    )

    ###########################################
    # Separating pieces of initial statistics #
    ###########################################
    log$info("Aggregating length of missing data...")
    node.nas <- lapply(initial.statistics, function(results){
        results[["data.na"]]
    })
    glob.nas <- vtg.summary::comb_na(node.nas, col)

    log$info("Aggregating node specific data lengths...")
    node.lengths <- lapply(initial.statistics, function(results){
        results[["data.lengths"]]})
    glob.lens <- vector(length=length(unique(col)))
    names(glob.lens) = unique(col)
    for(colName in unique(col)){
        # fast function
        identifies.values.of.columns <- mapply(FUN = function(vec){
            vec[which(names(vec) == colName)]}, node.lengths)
        # to remove the named numeric(0)
        identifies.values.of.columns <-
            Reduce("c", identifies.values.of.columns)
        glob.lens[[colName]] <- sum(identifies.values.of.columns)
    }

    log$info("Aggregating node specific sums...")
    node.sums <- lapply(initial.statistics, function(results){
        results[["data.sums"]]})
    glob.sums <- vtg.summary::comb_sums(node.sums, col)


    log$info("Aggregating node specific ranges...")
    node.range <- lapply(initial.statistics, function(results){
        results[["data.range"]]})
    glob.range <- vtg.summary::comb_range(node.range, col)

    log$info("Aggregating useable rows...")
    node.useable.rows <- lapply(initial.statistics, function(results){
        results[["data.useable.rows"]]
    })
    glob.useable.rows <- Reduce("sum", node.useable.rows)
    node.useable.rows.df <-
        data.frame("node" = seq_along(node.useable.rows),
                   "useable.rows" = Reduce("c", node.useable.rows),
                   row.names = NULL)
    # :@ R is still assigning rownames!!
    rownames(node.useable.rows.df) <- NULL

    log$info("Computing global means...")
    glob.mean <- vtg.summary::glob_mean(glob.sums, glob.lens, col)

    log$info("Calculating node specific squared deviance...")
    node.sqr.dev <- client$call(
        "sqr_dev",
        col = col,
        glob.mean = glob.mean
    )

    log$info("Aggregating squared deviance...")
    glob.sqr.dev <- vtg.summary::comb_sums(node.sqr.dev, col)

    log$info("Calculating global variance...")
    glob.var <- vtg.summary::glob_var(glob.sqr.dev, glob.lens, col)

    log$info("Calculating global standard deviation")
    glob.sd <- sapply(glob.var, sqrt)

    return(
        list(
            "global.nas" = glob.nas,
            "global.lengths" = glob.lens,
            "global.range" = glob.range,
            "global.means" = glob.mean,
            "global.variance" = glob.var,
            "node.specific.useable.rows" = node.useable.rows.df,
            "global.useable.rows" = glob.useable.rows
        )
    )
}
