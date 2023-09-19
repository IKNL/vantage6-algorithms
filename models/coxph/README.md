# vtg.coxph
Implementation of the Cox Proportional Hazards algorithm for the Vantage6 federated infrastructure.

## Installation
Run the following in the R console to install the package and its dependencies:
```R
# This also installs the package vtg
devtools::install_github('iknl/vtg.coxph', subdir="src")
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

# Define explanatory variables, time column and censor column
expl_vars <- c("Age","Race2","Race3","Mar2","Mar3","Mar4","Mar5","Mar9",
               "Hist8520","hist8522","hist8480","hist8501","hist8201",
               "hist8211","grade","ts","nne","npn","er2","er4")
time_col <- "Time"
censor_col <- "Censor"

# vtg.coxph contains the function `dcoxph`.
result <- vtg.coxph::dcoxph(client, expl_vars, time_col, censor_col)
```

## Example use for testing
```R
# Load a dataset
data('SEER', package='vtg.coxph')

# Define explanatory variables, time column and censor column
expl_vars <- c("Age","Race2","Race3","Mar2","Mar3","Mar4","Mar5","Mar9",
               "Hist8520","hist8522","hist8480","hist8501","hist8201",
               "hist8211","grade","ts","nne","npn","er2","er4")
time_col <- "Time"
censor_col <- "Censor"

result <- vtg.coxph::dcoxph.mock(SEER, expl_vars, time_col, censor_col)
```
