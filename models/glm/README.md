<img src="https://github.com/IKNL/guidelines/blob/master/resources/logos/vantage6.png?raw=true" width=200 align="right">

# vtg.glm
_Implementation of the federated Generalized Linear Model_

<p align="left">
  <a href="#usage">Usage</a> •
  <a href="#development">Development</a>
</p>

[![GLM Build](https://github.com/IKNL/vantage6-algorithms/actions/workflows/build-glm.yaml/badge.svg)](https://github.com/IKNL/vantage6-algorithms/actions/workflows/build-glm.yaml)

-----------------------------------------------------------------------------------------------------

## Intro
This repo includes an implementation of the federated Generalized Linear Model (GLM) for horizontally partitioned data.

Generalized Linear Models estimate regression models for outcomes following exponential distributions. The GLM generalizes linear regression by allowing the linear model to be related to the response variable via a link function and by allowing the magnitude of the variance of each measurement to be a function of its predicted value.

The current implementation is validated for the following R family inputs:
* gaussian(link = "identity"): gaussian regression
* binomial(link = "logit"): normal logistic regression
* poisson(link = "log"): poisson regression
* "rs.poi": custom glm relative survival model with poisson error

## Documentation 
Check "Technical Documentation - GLM" for technical details about the algorithm and more. (<- @TODO this should be a link to the .pdf)

## Installation
### R
Run the following in the R console to install the package and its dependencies:

```R
# This also installs the package vtg
devtools::install_github('iknl/vantage6-algorithms', subdir='models/glm/src')
```

## Run example
To follow the next examples, first prepare:
* a vantage6 server, 
* user, 
* 3 organizations, 
* a collaboration,
* 3 nodes, 
* and configure the nodes with the datasets "data_user1.csv", "data_user2.csv", "data_user3.csv" which you can find in iknl/vantage6-algorithms/models/glm/src/data.

### R
```R
setup.client <- function() {
  # Define parameters
  username <- 'username@example.com'
  password <- 'password'
  host <- 'https://address-to-vantage6-server.domain:port'
  api_path <- ''

  # Create the client
  client <- vtg::Client$new(host, api_path=api_path)
  client$authenticate(username, password)

  return(client)
}

# Create a client
client <- setup.client()

# Get a list of available collaborations
print( client$getCollaborations() )

# Should output something like this:
#   id     name
# 1  1 ZEPPELIN
# 2  2 PIPELINE

# Select a collaboration
client$setCollaborationId(1)

# vtg.dglm contains the function `dglm`.
model <- vtg.glm::dglm(client, formula = num_awards ~ prog + math, family='poisson', tol= 1e-08, maxit=25)
```

### Python

### API

## Builds
This repository is automatically built into a Docker image and pushed to our Docker image registry `harbor2.vantage6.ai`. If this is the `main` branch the image will be uploaded with the `latest` tag.

```
harbor2.vantage6.ai/algorithms/glm:latest
```

In case the `glm` branch is used the image is built and tagged with the shortened commit hash.

```
harbor2.vantage6.ai/algorithms/glm:COMMIT_HASH
```

## Notes
1. Added 'as.GLM.R' to convert the result to a glm/lm object
    * Simply wrap the object with the as.GLM -> as.GLM(object) where 'object' is the final output (the trained model).
