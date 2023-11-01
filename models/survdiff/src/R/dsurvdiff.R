#' Federated survdiff
#'
#' @param client vtg::Client instance, provided by the node
#' @param formula an object of class formula (or one that can be coerced
#'   to that class: a symbolic description of the model to be fitted.
#'   E.g.: dependant_variable ~ explanatory_variable(i) + ...
#' @param timepoints time points to calculate KM (bins instead of individual time point)
#'
#' @return  for each strata returns a table with (n events median 0.95LCL 0.95UCL) KM plot and ...
#'
#' @author Cellamare, M.
#' @author Alradhi, H.
#' @author Martin, F.
#' @export
#'
#'
dsurvdiff <- function(client, formula, timepoints=NULL,
                      organizations_to_include = NULL, subset_rules = NULL
                      ){

    vtg::log$debug("Initializing...")
    lgr::threshold("debug")

    image.name <- "harbor2.vantage6.ai/starter/survdiff"

    client$set.task.image(
        image.name,
        task.name="survdiff"
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

    # Parse a string to formula type. If it already is a formula this statement
    # will do nothing. This is needed when Python (or other langauges) is used
    # as a client.

    f <- as.formula(formula)

    # Run in a MASTER container. Note that this will call this method but then
    # within a Docker container. The client used here below has set the
    # property `use.master.container` set to `False`, therefore it will skip
    # this block (else an infinite loop would occur).

    if (client$use.master.container) {
        vtg::log$debug(glue::glue("Running `dsurvdiff` in master container using
                                  image '{image.name}'.."))
        result <- client$call(
            "dsurvdiff",
            formula = f,
            timepoints = timepoints,
            organizations_to_include = organizations_to_include,
            subset_rules = subset_rules
            )

        return(result)
    }
    # initialization variables
    vars=all.vars(f)
    LRT <- function(vars,stratum=NULL){
        if(length(vars)>3){
            master=list(time=vars[1],time2=vars[2],
                        event=vars[3],strata=vars[4],
                        timepoints=timepoints,tmax=tmax)
        }else{
            master=list(time=vars[1],time2=NA,
                        event=vars[2],strata=vars[3],
                        timepoints=timepoints,tmax=tmax)
        }
        if(is.null(timepoints)){
            vtg::log$info("RPC Time")
            node_time <- client$call(
                "time",
                subset_rules=subset_rules,
                master=master
            )
            master=vtg.survdiff::serv_time(nodes = node_time,master=master)
        }else{
            master=vtg.survdiff::serv_time(master=master)
        }

        vtg::log$info("RPC Tab")
        node_tab <- client$call(
            "tab",
            subset_rules=subset_rules,
            master=master,
            stratum=stratum
        )
        master=serv_tab(nodes = node_tab,master=master)
        return(master)
    }

    if(is.na(vars[3])){
        vtg::log$debug("missing stratification variable - [DONE]")
        break
    }else{
        vtg::log$info("RPC strata")
        node_strata <- client$call(
            "strata",
            subset_rules=subset_rules,
            strata=ifelse(length(vars)>3, vars[4], vars[3])
        )
        stratum=unique(unlist(node_strata))
        master=lapply(stratum, function(k) LRT(vars,k))
        names(master)=paste0(ifelse(length(vars)>3, vars[4], vars[3]),'=',stratum)
    }

    ######################################

    N=rowSums(sapply(1:length(master),function(g) master[[g]]$n))
    M=rowSums(sapply(1:length(master),function(g) master[[g]]$m))
    for(s in 1:length(master)){
        master[[s]]$e=(master[[s]]$n/N)*M
    }
    ###create Tab
    obs <- sapply(master, function(s) sum(s$m))
    exp <- sapply(master, function(s) sum(s$e))
    df=exp>0
    temp2 <- ((obs-exp)[df])[-1]
    V=matrix(NA,length(master),length(master))
    diag(V)=sapply(1:length(master), function(g){
        v=master[[g]]$n*(M/N)*((N-M)/N)*((N-master[[g]]$n)/(N-1))
        sum(v[!is.nan(v)])})
    EG=expand.grid(h=1:length(master),g=1:length(master))
    EG=EG[EG$h!=EG$g,]
    for(i in 1:nrow(EG)) {
        v=(master[[EG[i,1]]]$n*master[[EG[i,2]]]$n*M*(N-M))/(N^2*(N-1))
        V[EG[i,1],EG[i,2]]=-sum(v[!is.nan(v)])
    }
    vv <- (V[df,df])[-1,-1, drop=FALSE]
    colnames(V) <- names(master) #this has to be double-checked if OK.
    chi <- sum(solve(vv, temp2) * temp2)
    df <- (sum(1*(exp>0))) -1
    rval <-list(formula = formula,
                n = sapply(master, function(s) (s$n)[1]),
                strata = names(master),
                obs = obs,
                exp = exp,
                var = V,
                chisq = chi,
                pvalue = pchisq(chi, df, lower.tail=FALSE))

    df.rval <- as.data.frame(rval)

    vtg.survdiff::print_output_dsurvdiff(df.rval)
    vtg::log$debug("  - [DONE]")
    return(df.rval)
}

