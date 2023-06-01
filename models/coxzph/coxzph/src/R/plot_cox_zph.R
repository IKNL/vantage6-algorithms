#' This plots the Cox Zph and the Schoenfeld Residuals...
#' @importMethodsFrom splines ns
#' @export
plot_cox_zph <- function(cox_zph, resid=TRUE, se=TRUE, df=4, num_pts=40,
                         xlab="Time", ylab="", lty=1:2, col=1, lwd=1,
                         transform='identity'){
    event_time <- cox_zph$event_time
    sch_residuals <- cox_zph$sch_residuals
    betavar <- cox_zph$betavar
    df <- max(df)
    nvar <- ncol(sch_residuals)
    pred.x <- seq(from=min(event_time), to=max(event_time), length=num_pts)
    temp <- c(pred.x, event_time)
    lmat <- ns(temp, df=df, intercept=TRUE)
    # for prediction
    pmat <- lmat[1:num_pts,]
    xmat <- lmat[-(1:num_pts),]
    ylab <- paste("Beta(t) for", dimnames(sch_residuals)[[2]])
    if (transform == 'log') {
        event_time <- exp(event_time)
        pred.x <- exp(pred.x)
    }
    col <- rep(col, length=2)
    lwd <- rep(lwd, length=2)
    lty <- rep(lty, length=2)
    for (i in 1:nvar) {
        y <- sch_residuals[,i]
        keep <- !is.na(y)
        if (!all(keep)) y <- y[keep]
        qmat <- qr(xmat[keep,])
        if (qmat$rank < df) {
            warning("spline fit is singular, variable ", i, " skipped")
            next
        }
        yhat <- pmat %*% qr.coef(qmat, y)
        if (resid){ yr <-range(yhat, y)
        }else {yr <-range(yhat)}
        if (se) {
            bk <- backsolve(qmat$qr[1:df, 1:df], diag(df))
            xtx <- bk %*% t(bk)
            seval <- ((pmat%*% xtx) *pmat) %*% rep(1, df)

            temp <- 2*sqrt(betavar[i,i]*seval)
            yup <- yhat + temp
            ylow<- yhat - temp
            yr <- range(yr, yup, ylow)
        }
        if (transform=='identity'){
            plot(range(event_time), yr, type='n', xlab=xlab, ylab=ylab[i],
                 main="Federated")
        }
        if (transform=='log'){
            plot(range(event_time[keep]), yr, type='n', xlab=xlab,
                 ylab=ylab[i],log='x',main="Federated")
        }
        if (resid){
            points(event_time[keep], y)
        }
        lines(pred.x, yhat, lty=lty[1], col=col[1], lwd=lwd[1])
        if (se){
            lines(pred.x, yup,  col=col[2], lty=lty[2], lwd=lwd[2])
            lines(pred.x, ylow, col=col[2], lty=lty[2], lwd=lwd[2])
        }
    }
}