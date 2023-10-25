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

    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

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
        vtg::log$debug(glue::glue("Running `dsummary` in master container using
                                  image '{image.name}'.."))
        result <- client$call(
            "dsummary",
            col = col,
            threshold = threshold
        )

        return(result)
    }

    vtg::log$info("RPC get NA")
    node.nas <- client$call(
        "get_NA",
        col = col,
        threshold = threshold
    )

    glob.nas <- vtg.summary::comb_na(node.nas, col)

    vtg::log$info("RPC N")
    node.lens <- client$call(
        "N",
        col = col,
        threshold = threshold
    )

    glob.lens <- vtg.summary::comb_N(node.lens, col)

    vtg::log$info("RPC range")
    node.range <- client$call(
        "range",
        col = col,
        threshold = threshold
    )

    glob.range <- vtg.summary::comb_range(node.range, col)

    vtg::log$info("RPC sums")
    node.sums <- client$call(
        "sums",
        col = col,
        threshold = threshold
    )

    glob.sums <- vtg.summary::comb_sums(node.sums, col)

    glob.mean <- vtg.summary::glob_mean(glob.sums, glob.lens, col)

    vtg::log$info("RPC sqr dev")
    node.sqr.dev <- client$call(
        "sqr_dev",
        col = col,
        glob_mu = glob.mean
    )

    glob.sqr.dev <- vtg.summary::comb_sums(node.sqr.dev, col)

    glob.var <- vtg.summary::glob_var(glob.sqr.dev, glob.lens, col)

    glob.sd <- sapply(glob.var, sqrt)

    structure(
        list(
            "NA:" = node.nas,
            "N" = glob.lens,
            "Range" = glob.range,
            "Sums" = glob.sums,
            "Mean" = glob.mean,
            "Variance" = glob.var,
            "Standard-deviation" = glob.sd
        )
    )
}