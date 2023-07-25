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
dct <- function(client, f){

    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

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

    return(ct)

}