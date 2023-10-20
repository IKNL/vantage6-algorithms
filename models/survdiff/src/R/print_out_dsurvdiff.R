#' @export
#'
print_output_dsurvdiff <- function(x,...){
  cat('Call:\ndsurvdiff(formula =',as.character(x$formula)[c(2,1,3)],',data)',
      sep = ' ')
  cat("\n\n")
  print(
        cbind("N"=x$n,"Observed"=x$obs, "Expected"=round(x$exp,2),
              "(O-E)^2/E"=round(((x$obs-x$exp)^2)/x$exp,3),
              "(O-E)^2/V"=round(((x$obs-x$exp)^2)/diag(x$var),3))
        )
  cat("\n")
  cat('Chisq= ',round(x$chi,1),' on ',length(x$stratum)-1,
      ' degrees of freedom, p= ',round(x$pvalue,3))
  invisible(x)
}
