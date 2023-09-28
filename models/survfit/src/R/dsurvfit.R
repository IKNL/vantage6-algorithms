#' Federated survfit (Kaplan Mayer)
#'
#' @param client vtg::Client instance, provided by the node
#' @param formula an object of class formula (or one that can be coerced
#'   to that class: a symbolic description of the model to be fitted.
#'   E.g.: dependant_variable ~ explanatory_variable(i) + ...
#' @param conf.int confidence interval coverage (95% default)
#' @param conf.type type of confidence interval (log, identity, log-log)
#' @param timepoints time points to calculate KM (bins instead of individual time point)
#' @param plotCI True if the researcher wants to plot Confidence Interval for the KM curves
#' @param organizations_to_include either NULL meaning all participating organizations
#' or select organizations ids; must be list of id(s)
#'
#' @return  for each strata returns a table with (n events median 0.95LCL 0.95UCL) KM plot and ...
#'
#' @author Cellamare, M.
#' @author Alradhi, H.
#' @author Martin, F.
#'
#' @export
#'
dsurvfit <- function(client,formula,conf.int=0.95,conf.type='log',
                     timepoints=NULL,plotCI=F,
                     organizations_to_include = NULL){

    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

    image.name <- "harbor2.vantage6.ai/starter/survfit:latest"

    client$set.task.image(
        image.name,
        task.name="survfit"
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

     # Parse a string to formula type. If it already is a formula this statement
    # will do nothing. This is needed when Python (or other langauges) is used
    # as a client.

    formula <- as.formula(formula)

    # Run in a MASTER container. Note that this will call this method but then
    # within a Docker container. The client used here below has set the
    # property `use.master.container` set to `False`, therefore it will skip
    # this block (else an infinite loop would occur).

    if (client$use.master.container) {
        vtg::log$debug(glue::glue("Running `dsurvfit` in master container using
                                  image '{image.name}'.."))
        result <- client$call(
            "dsurvfit",
            formula = formula,
            conf.int = conf.int,
            conf.type = conf.type,
            timepoints = timepoints,
            plotCI = plotCI
        )

        return(result)
    }
    # initialization variables
    vars=all.vars(formula)
    KM <- function(vars,stratum=NULL){
        master=list(time=vars[1],event=vars[2],strata=vars[3],
                    conf.int=conf.int,conf.type=conf.type,
                    timepoints=timepoints)
        if(is.null(timepoints)){
            vtg::log$info("RPC Time")
            node_time <- client$call(
                "time",
                master=master,
                stratum=stratum
            )
            master=vtg.survfit::serv_time(nodes = node_time,master=master)
        }else{
            master=vtg.survfit::serv_time(master=master)
        }

        vtg::log$info("RPC at risk")
        node_at_risk <- client$call(
            "at_risk",
            master=master,
            stratum=stratum
        )
        master=serv_at_risk(nodes = node_at_risk,master=master)

        vtg::log$info("RPC KM surv")
        node_KMsurv <- client$call(
            "KMsurv",
            master=master,
            stratum=stratum
        )
        master=vtg.survfit::serv_KM(nodes = node_KMsurv,master=master)
        return(master)
    }

    if(is.na(vars[3])){
         master=list(KM(vars))
    }else{
        vtg::log$info("RPC strata")
        node_strata <- client$call(
            "strata",
            strata=vars[3]
        )
        stratum=unique(unlist(node_strata))
        master=lapply(stratum, function(k) KM(vars,k))
        names(master)=paste0(vars[3],'=',stratum)
    }

    ######################################

    Tab <- sapply(1:length(master), function(i){
        med=which(master[[i]]$surv<=.5)[1]
        medL=which(master[[i]]$lower<=.5)[1]
        medU=which(master[[i]]$upper<=.5)[1]
        tab=c(master[[i]]$n.at.risk[1],master[[i]]$n.events,
              master[[i]]$times[med],master[[i]]$times[medL],
              master[[i]]$times[medU])
        return(tab)
    })
    Tab=as.table(t(Tab))
    row.names(Tab)=names(master)
    colnames(Tab)=c('n','events','median','0.95LCL','0.95UCL')
    master$Tab=Tab
    print(master$Tab)
    jpeg(filename = "plotKM_plot%03d.jpg", width = 960, height = 960,
         quality = 100)
    vtg.survfit::plotKM(master, plotCI = plotCI)
    dev.off()
    vtg::log$debug("  - [DONE]")
    return(master$Tab)

}