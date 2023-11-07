#' Federated Summary algorithm.
#'
#' This version has built in `threshold` parameter that checks if any counts
#' are less than tolerance. Default is 5. Can go lower (to 1). Up to data-owner.
#' @param client vtg::Client instance provided by node (datastation).
#' @param col Can by single column name or N column name.
#' @param threshold Disclosure check. Default is 5, if number of counts in
#' any cell is less than `threshold` the function stops and returns an error
#' message.
#'
#' @author Hasan Alradhi
#' @author Matteo Cellamare
#' @author Frank Martin
#'
#' @export
#'
dsummary <- function(client, col, threshold = 5L,
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

    log$info("RPC get NA")
    # this now also shows which columns are available on which data!
    node.nas <- client$call(
        "get_NA",
        col = col
    )

    log$info("Aggregating total missing columns...")
    list.glob.nas <- vtg.summary::comb_na(node.nas, col)
    glob.nas <- Reduce("c", list.glob.nas)
    names(glob.nas) <- names(list.glob.nas)


    # TODO: Order of input must match... so Node 1 has to correspond to
    # the first dataset in the "list" of datasets... Of course this is handled
    # internally with the Client.
    cols.in.nodes <- lapply(seq(length(node.nas)), function(x){
        paste("node", x, "has columns:", paste0(names(node.nas[[x]]),
                                                   collapse = " ,"))})


    log$info("Calculating Node specific column lengths...")
    node.lens <- client$call(
        "len_col",
        col = col,
        threshold = threshold
    )

    log$info("Creating global column lengths...")
    glob.lens <- vector(length=length(unique(col)))
    names(glob.lens) = unique(col)
    for(colName in col){
        identifies.values.of.columns <- mapply(FUN = function(vec){
            vec[which(names(vec) == colName)]}, node.lens)
        # to remove the named numeric(0)
        identifies.values.of.columns <- Reduce("c",
                                               identifies.values.of.columns)
        glob.lens[[colName]] <- sum(identifies.values.of.columns)
    }

    log$info("Calculating node specific useable rows...")
    node.useable.rows <- client$call(
        "useable_rows_in_data",
        col = col,
        threshold = threshold
    )

    # TODO : this has to be something added to the client as the previous
    # todo...
    useable.rows.per.node <- lapply(seq(length(node.useable.rows)),function(x){
        paste("node", x, "has", node.useable.rows[[x]], "useable rows.")})

    glob.useable.rows <- Reduce("sum", node.useable.rows)

    log$info("Calculating node specific range per column")
    node.range <- client$call(
        "range",
        col = col,
        threshold = threshold
    )

    log$info("Calculating global range")
    glob.range <- vtg.summary::comb_range(node.range, col)

    log$info("Calculating node specific sums per column")
    node.sums <- client$call(
        "sums",
        col = col,
        threshold = threshold
    )

    log$info("Calculating global sum per column")
    glob.sums <- vtg.summary::comb_sums(node.sums, col)

    log$info("Calculating global mean per column")
    glob.mean <- vtg.summary::glob_mean(glob.sums, glob.lens, col)

    log$info("Calculating node specific squared deviance")
    node.sqr.dev <- client$call(
        "sqr_dev",
        col = col,
        glob.mean = glob.mean
    )

    log$info("Calculating global squared deviance")
    glob.sqr.dev <- vtg.summary::comb_sums(node.sqr.dev, col)

    log$info("Calculating global variance")
    glob.var <- vtg.summary::glob_var(glob.sqr.dev, glob.lens, col)

    log$info("Calculating global standard deviation")
    glob.sd <- sapply(glob.var, sqrt)

    summaries <- list(
        "global.na.per.column" = glob.nas,
        "global.length.data" = glob.lens,
        "global.range"=glob.range,
        "global.sums"=glob.sums,
        "global.means"=glob.mean,
        "global.variance"=glob.var,
        "global.sqr.dev"=glob.sqr.dev,
        "global.std.dev"=glob.sd,
        "columns.in.nodes"=cols.in.nodes,
        "useable.rows.in.nodes"=useable.rows.per.node,
        "global.useable.rows"=glob.useable.rows
    )
    return(summaries)
}
