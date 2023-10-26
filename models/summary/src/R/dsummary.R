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
        col = col
    )

    glob.nas <- vtg.summary::comb_na(node.nas, col)

    cols.in.nodes <- lapply(seq(length(node.nas)), function(x){
        paste("node ", x, " has columns: ", paste0(names(node.nas[[x]]),
                                                   collapse = " ,") )
    })


    vtg::log$info("RPC len col")
    node.lens <- client$call(
        "len_col",
        col = col,
        threshold = threshold
    )

    glob.lens <- vtg.summary::comb_N(node.lens, col)

    vtg::log$info("RPC N row")
    node.row.lens <- client$call(
        "N_row",
        col = col,
        threshold = threshold
    )

    glob.row.len <- Reduce("sum",lapply(node.row.lens, function(x) x))

    local.rows.len <- lapply(seq(length(node.row.lens)), function(x){
        paste("node ", x, " has: ", node.row.lens[[x]], " rows." )
    })

    # we want to send back which nodes contain an NA while checking that there
    # is no disclosure risk of doing so...

    node.na.cols <- vector("list", length = length(node.lens))

    node.na.cols <-
        lapply(seq(length(node.lens)), function(x){
            if( all( (check <- lapply(node.lens[[x]], function(i) i) >
                      threshold ) )){
                node.na.cols[[x]] <- sapply(node.nas[[x]], function(j) j)
                new_vector <- c(Reduce("c", node.na.cols[[x]]) )
                non_null_names <- names(node.nas[[x]])[!sapply(node.nas[[x]],
                                                               is.null)]
                names(new_vector) <- non_null_names
                node.na.cols[[x]] <- new_vector

            }else{
                stop(paste0("Disclosure risk from node, ", x, "column: ",
                            names(x)[which(sapply(check, isFALSE), arr.ind = T)
                                     ]))
            }
        })

    missing.cols <- lapply(seq(length(node.na.cols)), function(x){
        paste("node ", x, " has NA in the following columns: ",
              paste0(names(node.na.cols[[x]]),collapse = " ,") )
    })

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

    vtg::log$info("combining sums")

    glob.sums <- vtg.summary::comb_sums(node.sums, col)

    glob.mean <- vtg.summary::glob_mean(glob.sums, glob.lens, col)

    vtg::log$info("RPC sqr dev")
    node.sqr.dev <- client$call(
        "sqr_dev",
        col = col,
        glob_mu = glob.mean
    )

    glob.sqr.dev <- vtg.summary::comb_sums(node.sqr.dev, col)

    glob.var <- data.frame(vtg.summary::glob_var(glob.sqr.dev, glob.lens, col))

    glob.sd <- sapply(glob.var, sqrt)

    structure(
        list(
            "NA:" = glob.nas,
            "total.len.data" = glob.lens,
            "range" = glob.range,
            "sum" = glob.sums,
            "mean" = glob.mean,
            "var" = glob.var,
            "sqr.dev.sum" = glob.sqr.dev,
            "std.dev" = glob.sd,
            "missing.columns" = missing.cols,
            "columns.in.nodes" = cols.in.nodes,
            "total.row.len.na.included" = glob.row.len,
            "local.row.len.na.included" = local.rows.len
        )
    )
}
