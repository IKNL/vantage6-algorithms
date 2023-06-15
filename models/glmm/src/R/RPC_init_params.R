#'@export
RPC_init_params <- function(formula, family, data, start){
    # this function will run a GLM and average the estimates over each site...
    # just to speed up convergence
    formula = update(formula, . ~ . - (1 | herd) - (1 | obs))
    return(glm(
        formula=formula, family=family, data=data, start=start,...
    ))
}
