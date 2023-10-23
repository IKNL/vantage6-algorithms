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

dct <- function(client, f, margin = NULL, percentage = F,
                organizations_to_include = NULL, subset_rules = NULL){

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
        organizations_in_collaboration = client$collaboration$organizations
        # Clear the current list of organizations in the collaboration
        # Will remove them for current task, not from actual collaboration
        client$collaboration$organizations <- list()
        # Reshape list when the organizations_to_include is not already a list
        # Relevant when e.g., Python is used as client
        if (!is.list(organizations_to_include)){
            organizations_to_use <- toString(organizations_to_include)

            # Remove leading and trailing spaces as in python list
            organizations_to_use <-
                gsub(" ", "", organizations_to_use, fixed=TRUE)

            # Convert to list assuming it is comma separated
            organizations_to_use <-
                as.list(strsplit(organizations_to_use, ",")[[1]])
        }
        # Loop through the organization ids in the collaboration
        for (organization in organizations_in_collaboration) {
            # Include the organizations only when desired
            if (organization$id %in% organizations_to_use) {
                client$collaboration$organizations[[length(
                    client$collaboration$organizations)+1]] <- organization
            }
        }
    }

    ct <- init_formula(f)

    if (client$use.master.container){
        vtg::log$debug(glue::glue("Running `dct` in master container using
                                  image '{image.name}'.."))
        result <- client$call(
            "dct",
            f = f,
            margin = margin,
            percentage = percentage,
            organizations_to_include = organizations_to_include,
            subset_rules = subset_rules
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
        subset_rules = subset_rules,
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
        subset_rules = subset_rules,
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