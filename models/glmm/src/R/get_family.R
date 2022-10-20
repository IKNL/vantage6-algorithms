get_family <- function(family, dstar = NULL) {

    # Functions of the family required (gaussian, poisson, logistic,...)
    if (is.character(family))
    {
        if(family == 'rs.poi')
        {
            if(is.null(dstar))
            {
                vtg::log$debug("expected count required for relative survival")
                return()
            }
            family <- poisson()
            family$family <- "rs.poi"
            family$link <- "glmm relative survival model with Poisson error"
            family$linkfun <- function(mu) log(mu - dstar)
            family$linkinv <- function(eta) dstar + exp(eta)
        } else {
            family <- get(family, mode = "function", envir = parent.frame())()
        }
    }

    if (is.function(family)){
        family <- family()
    }

    if (is.null(family$family)){
        stop(glue::glue("family '{family}' not recognized"))
    }

    return(family)
}