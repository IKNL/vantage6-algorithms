#'@export
RPC_initparams <- function(data, formula_str, family, ...){
    # this function will run a GLM and average the estimates over each site...
    # just to speed up convergence
    # formula = update(formula, . ~ . - (1 | herd) - (1 | obs))
    f <- formula_str
    f <- gsub("\\s*\\+\\s*\\(1[[:space:]]*\\|[[:space:]]*[^)]+\\)", "", f)
    # f <- as.formula(paste(f[2], f[1], f[3:length(f)]))
    # f <- reformulate(response = f[2], termlabels = f[3:length(f)], environment = environment(formula))
    # ans <- glm(formula=f, family=family, data=data,...)
    response <- as.name(f[2])
    terms <- as.list(parse(text = paste(f[3:length(f)], collapse = " ")))
    new_formula <- as.formula(paste(response, "~", paste(terms, collapse = " + ")))
    ans <- glm(formula = new_formula, family = family, data = data, ...)
    ## varcovar <- vcov(ans);get the RE?
    return(as.vector(ans$coefficients))
}
