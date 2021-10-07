as.GLM <- function(obj, data=NULL) {
  #fill a GLM object with output of the Federated Learning GLM
  dots <- as.list(obj$coefficients)
  
  out<-list()
  
  tt <- terms(obj$formula, data=data)
  
  if(!is.null(data)) {
    
    mf <- model.frame(tt, data)
    
    vn <- sapply(attr(tt, "variables")[-1], deparse)
    
    
    tt=M_2$terms
    vn <- sapply(attr(tt, "variables")[-1], deparse)
    
    
    
    if((yvar <- attr(tt, "response"))>0)
      
      vn <- vn[-yvar]
    
    xlvl <- lapply(data[vn], function(x) if (is.factor(x))
      
      levels(x)
      
      else if (is.character(x))
        
        levels(as.factor(x))
      
      else
        
        NULL)
    
    attr(out, "xlevels") <- xlvl[!vapply(xlvl,is.null,NA)]
    
    attr(tt, "dataClasses") <- sapply(data[vn], stats:::.MFclass)
    
  }
  
  out$terms <- tt
  
  coef <- numeric(0)
  
  stopifnot(length(dots)>1 & !is.null(names(dots)))
  
  for(i in seq_along(dots)) {
    
    if((n<-names(dots)[i]) != "") {
      
      v <- dots[[i]]
      
      if(!is.null(names(v))) {
        
        coef[paste0(n, names(v))] <- v
        
      } else {
        
        stopifnot(length(v)==1)
        
        coef[n] <- v
        
      }
      
    } else {
      
      coef["(Intercept)"] <- dots[[i]]
      
    }   
    
  }
  
  out$coefficients <- coef
  
  out$rank <- length(coef)
  
  family=obj$family
  
  if (!missing(family)) {
    
    out$family <- if (class(family) == "family") {
      
      family
      
    } else if (class(family) == "function") {
      
      family()
      
    } else if (class(family) == "character") {
      
      get(family)()
      
    } else {
      
      stop(paste("invalid family class:", class(family)))
      
    }
    
    out$qr <- list(pivot=seq_len(out$rank))
    
    out$deviance <- obj$deviance
    
    out$null.deviance <- obj$null.deviance
    
    out$aic <- 1
    
    out$iter=obj$iter
    
    out$df.null=obj$nobs-1
    
    out$df.residual=obj$nobs-out$rank
    
    out$call=call("glm_FL",formula,family=obj$family$family)
    
    class(out) <- c("glm","lm")
    
    
  } else {
    
    class(out) <- "lm"
    
    out$fitted.values <- predict(out, newdata=dd)
    
    out$residuals <- out$mf[attr(tt, "response")] - out$fitted.values
    
    out$df.residual <- nrow(data) - out$rank
    
    out$model <- data
    
    #QR doesn't work
    
  }
  
  out
  
}