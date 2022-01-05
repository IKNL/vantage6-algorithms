<img src="https://github.com/IKNL/guidelines/blob/master/resources/logos/vantage6.png?raw=true" width=200 align="right">

# vtg.glm
_Implementation of the federated Generalized Linear Model_

<p align="left">
  <a href="#usage">Usage</a> •
  <a href="#development">Development</a>
</p>

[![GLM Build](https://github.com/IKNL/vantage6-algorithms/actions/workflows/build-glm.yaml/badge.svg)](https://github.com/IKNL/vantage6-algorithms/actions/workflows/build-glm.yaml)

-----------------------------------------------------------------------------------------------------

## Usage

### Installation
Run the following in the R console to install the package and its dependencies:

```R
# This also installs the package vtg
devtools::install_github('iknl/vantage6-algorithms', subdir='models/glm/src')
```

### Run example
```R
setup.client <- function() {
  # Define parameters
  username <- 'username@example.com'
  password <- 'password'
  host <- 'https://address-to-vantage6-server.domain'
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

### Notes
1. Added as.GLM.R to convert the result to a glm/lm object
    * Simply wrap the object with the as.GLM -> as.GLM(object) where 'object' is the final output (the trained model)

## Development

### Automatic Building

This repository is automatically build into an Docker image and pushed to our Docker image registry `harbor2.vantage6.ai`. If this is the `main` branch the image will be uploaded with the `latest` tag.

```
harbor2.vantage6.ai/algorithms/glm:latest
```

In case the `glm` branch is used the image is build and tagged with the shortened commit hash.

```
harbor2.vantage6.ai/algorithms/glm:COMMIT_HASH
```
