#' @importMethodsFrom glue glue
dcoxzph <- function(client, fit, time, event, transform='identity',resid=TRUE,
                    se=TRUE, df=4,num_pts=40, xlab="Time", ylab="", lty=1:2,
                    col=1, lwd=1, organizations_to_include=NULL){

    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

    stopifnot(!is.null(fit))

    image.name <- "harbor2.vantage6.ai/starter/coxzph:latest"

    client$set.task.image(
        image.name,
        task.name="coxzph"
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
            transform = transform
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
    coxfit <- vtg.coxzph::coxfit(fit, transform)

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
    coxfit <- vtg.coxzph::sort_vars_list(
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
    coxfit <- vtg.coxzph::hazard_ratio(
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
        time = time,
        event = event,
        coxfit = coxfit
    )
    #######################################################################
    # Testing the Cox Proportionality Assumption
    #######################################################################
    coxfit <- vtg.coxzph::test_cox_zph(
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