serv_time=function(nodes=NULL,master=NULL){
    if(is.null(master$timepoints)){
        master$times = sort(unique(unlist(nodes)))
    }else{
        master$times = master$timepoints
    }
    return(master)
}