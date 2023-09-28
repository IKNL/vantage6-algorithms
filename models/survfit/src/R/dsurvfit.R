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
#'
#' @return  for each strata returns a table with (n events median 0.95LCL 0.95UCL) KM plot and ...
#'
#' @author Cellamare, M.
#' @author Alradhi, H.
#' @author Martin, F.
#'

dsurvfit=function(client,formula,conf.int=0.95,conf.type='log',timepoints=NULL,plotCI=F){
    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

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
        master=list(time=vars[1],event=vars[2],strata=vars[3],conf.int=conf.int,conf.type=conf.type,timepoints=timepoints)
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
    Tab=sapply(1:length(master), function(i){
        med=which(master[[i]]$surv<=.5)[1]
        medL=which(master[[i]]$lower<=.5)[1]
        medU=which(master[[i]]$upper<=.5)[1]
        tab=c(master[[i]]$n.at.risk[1],master[[i]]$n.events,
              master[[i]]$times[med],master[[i]]$times[medL],master[[i]]$times[medU])
        return(tab)
    })
    Tab=as.table(t(Tab))
    row.names(Tab)=names(master)
    colnames(Tab)=c('n','events','median','0.95LCL','0.95UCL')
    master$Tab=Tab
    vtg.survfit::plotKM(master,plotCI = plotCI)
    print(master$Tab)
    vtg::log$debug("  - [DONE]")
    return(master)
}