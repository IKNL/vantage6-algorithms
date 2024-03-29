% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RPC_node_deviance.R
\name{RPC_node_deviance}
\alias{RPC_node_deviance}
\title{RPC call for the second data loop of the federated GLM}
\usage{
RPC_node_deviance(
  data,
  formula,
  family,
  first_iteration,
  dstar,
  coeff,
  coeff_old,
  wtdmu,
  types = NULL,
  weights = NULL
)
}
\arguments{
\item{data}{dataframe containing the data}

\item{weights}{an optional vector of ‘prior weights’ to be used in the
fitting process. Should be NULL or a numeric vector.}

\item{master}{a list of parameters used to compute the GLM}
}
\value{
GLM partials
}
\description{
RPC call for the second data loop of the federated GLM
}
