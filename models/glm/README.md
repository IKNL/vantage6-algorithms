# vtg.dglm
Implementation of the federated Generalized Linear Model for the [vantage6](https://github.com/IKNL/VANTAGE6) federated infrastructure.

## Installation
Run the following in the R console to install the package and its dependencies:

```R
# This also installs the package vtg
devtools::install_github('iknl/vtg.dglm', subdir='src')
```

## Example use
```R
setup.client <- function() {
  # Define parameters
  username <- "username@example.com"
  password <- "password"
  host <- 'https://trolltunga.vantage6.ai'
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
model <- vtg.glm::dglm(client, formula = num_awards ~ prog + math, family="poisson",tol= 1e-08,maxit=25)
```

## Notes
1. Added as.GLM.R to convert the result to a glm/lm object 
    * Simply wrap the object with the as.GLM -> as.GLM(object) where 'object' is the final output (the trained model)
