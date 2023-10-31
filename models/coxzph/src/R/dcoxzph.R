#' @importMethodsFrom glue glue
#' @export
#'
dcoxzph <- function(client, fit, time, event, transform='identity',resid=TRUE,
                    se=TRUE, df=4,num_pts=40, xlab="Time", ylab="", lty=1:2,
                    col=1, lwd=1, organizations_to_include=NULL,
                    subset_rules=NULL){

    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

    stopifnot(!is.null(fit))

    #image.name <- "harbor2.vantage6.ai/starter/coxzph:latest"
    image.name <- "my_coxzph2"

    client$set.task.image(
        image.name,
        task.name="coxzph"
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

    if (client$use.master.container) {
        vtg::log$debug(glue("Running `dcoxzph` in master container using image
                            `{image.name}`...`"))
        result <- client$call(
            "dcoxzph",
            fit = coxfit,
            resid = resid,
            se = se,
            df = df,
            num_pts = num_pts,
            xlab = xlab,
            ylab = ylab,
            lty = lty,
            col = col,
            lwd = lwd,
            transform = transform,
            organizations_to_include = organizations_to_include,
            subset_rules = subset_rules
        )
        return(result)
    }

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Extracting Beta and Betavar from `fit`")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # Central Part of algorithm - Global Beta and Betavar
    #######################################################################
    coxfit <- coxfit(fit, transform)

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Extracting all unique time events")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # RPC NODE BETA - COMPUTE BETA PARTIALS
    #######################################################################
    unique_events <- client$call(
        "extract_event_times",
        subset_rules = subset_rules,
        time = time,
        event = event
    )

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Updating coxfit with the unique events")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # Updating coxfit with the unique events
    #######################################################################
    coxfit <- sort_vars_list(
        nodes = unique_events,
        coxfit = coxfit
    )

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Calculating Ratio")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # Calculating Ratio
    #######################################################################
    ratio <- client$call(
        "ratio",
        subset_rules = subset_rules,
        time = time,
        event = event,
        coxfit = coxfit
    )

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Calculating Hazard Ratio, updating coxfit")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # Calculating Hazard Ratio, updating coxfit
    #######################################################################
    coxfit <- hazard_ratio(
        nodes = ratio,
        coxfit = coxfit
    )

    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Calculating Schoenfeld Residuals")
    vtg::log$info("###############################################")
    vtg::log$info("")
    #######################################################################
    # Calculating Schoenfeld Residuals
    #######################################################################
    schoenfeld_residuals <- client$call(
        "schoenfeld_residuals",
        subset_rules = subset_rules,
        time = time,
        event = event,
        coxfit = coxfit
    )
    #######################################################################
    # Testing the Cox Proportionality Assumption
    #######################################################################
    coxfit <- test_cox_zph(
        partials = schoenfeld_residuals,
        coxfit = coxfit
    )
    vtg::log$info("")
    vtg::log$info("###############################################")
    vtg::log$info("# Plotting CoxZPH.")
    vtg::log$info("###############################################")
    vtg::log$info("")

    return(coxfit)


}