as.GLMM <- function(result, data=NULL){

    fixed_effects <- result$fixed_effects

    random_effect <- result$random_effect

    title <- result[[1]][1]

    # terms <- terms(as.formula(result$formula), data = data)

    out <- list()

    if(!is.null(data)){

        mf <- model.frame(lme4::subbars(as.formula(result$formula)), data=data)

        terms <- terms(subbars(as.formula(result$formula)))

        vars <- sapply(attr(terms, "variables")[-1], deparse)

        if(yvar <- attr(terms, "response")>0){
            vars <- vars[-yvar]
        }

        xlvl <- lapply(data[vars], function(i) {
            if(is.factor(i)){
                levels(i)
            }else if(is.character(i)){
                levels(as.factor(i))
            }else{
                NULL
            }
        })

        attr(out, "xlevels") <- xlvl[!vapply(xlvl, is.null, NA)]
        attr(terms, "dataClasses") <- sapply(data[vars], stats:::.MFclass)

    }

    out$terms <- terms

    stopifnot(length(random_effect) == 1
              & length(fixed_effects) > 1
              & !is.null(names(random_effect))
              & !is.null(names(fixed_effects)))


    Groups =  gsub(pattern = ".(Intercept)", x = names(y$random_effect), fixed = T, replacement = "")
    Name = gsub(pattern = paste0(Groups,"."), replacement = "", x = names(y$random_effect), fixed = T)
    Std.Dev. = y$random_effect[[1]]

    out$"Random effects:" <- data.frame("Groups" = Groups, "Name" = Name, "Std.Dev." = Std.Dev.)
    row.names(out$"Random effects:") <- ""


}