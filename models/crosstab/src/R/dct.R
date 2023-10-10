#' Federated Cross Tabulation
#'
#' @param client vtg::Client instance, provided by the node
#' @param f an object of class formula
#'
#' @return Federated Cross Table object.
#'
#' @author Alradhi, H.
#' @author Cellamare, M.
#'
#' @export
#'
dct <- function(client, f, margin = NULL, percentage = F,
                organizations_to_include = NULL){

    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

    image.name <- "harbor2.vantage6.ai/starter/crosstab"

    client$set.task.image(
        image.name,
        task.name="crosstab"
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

    ct <- init_formula(f)

    if (client$use.master.container){
        vtg::log$debug(glue::glue("Running `dct` in master container using
                                  image '{image.name}'.."))
        result <- client$call(
            "dct",
            f = f
        )
        return(result)
    }

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Collecting local variables...")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # RPC GET VARS - GET UNIQUE VARIABLES AT EACH NODE
    #######################################################################
    nodes <- client$call(
        "get_vars",
        master = ct
    )

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Collecting variable categories...")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # VARIABLE CATEGORIES - COLLECT UNIQUE VARIABLE CATEGORIES FROM NODES
    #######################################################################
    ct <- vtg.crosstab::variable_categories(
        nodes = nodes,
        master = ct
    )

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Building local contingency table... ")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # RPC CT - BUILD LOCAL CONTINGENCY TABLE
    #######################################################################
    nodes <- client$call(
        "CT",
        master = ct
    )

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Calculating global contingency table... ")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # ADD CTS - CREATE GLOBAL CONTINGENCY TABLE
    #######################################################################
    ct <- vtg.crosstab::add_cts(
        nodes = nodes,
        master = ct
    )

    if(!is.null(margin) && (is.integer(margin)) && (1 <= margin) &&
       (3 >= margin)){
        ct <- vtg.crosstab::proportion(ct, margin)
    }

    if(!isFALSE(percentage))
        # TODO : This should loop ideally over the nodes but only
        # return the right node result to the client, not
        # all results should be sent!!!
        node.contribution <- percentage(node[[1]], output)

    df.ct <- as.data.frame(ct)

    return(df.ct)

}