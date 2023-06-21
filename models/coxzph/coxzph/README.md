<img src="https://github.com/IKNL/guidelines/blob/master/resources/logos/iknl_nl.png?raw=true" width=200 align="right">

# Federated Cox Z-score PH (CoxZPH)
_Implementation of the federated Cox Z-score PH (CoxZPH) for horizontally-partitioned data_

<p align="left">
  <a href="#handshake-introduction">Introduction</a> •
  <a href="#computer-installation">Installation</a> •
  <a href="#man_technologist-examples">Examples</a> •
  <a href="#books-documentation">Documentation</a> •
  <a href="#building_construction-builds">Builds</a> •
  <a href="#balance_scale-validation">Validation</a> •
  <a href="#spiral_notepad-notes">Notes</a> •
  <a href="#black_nib-references">References</a>
</p>

-----------------------------------------------------------------------------------------------------

## :handshake: Introduction
This repository includes an implementation of the federated Cox Z-score PH for horizontally partitioned data.

Cox Z-score PH is a useful tool for validating the proportionality assumption under the Cox regression via a (Schoenfeld) residual-plot. 

The algorithm is implemented in R and can be easily used in R as well.

## :computer: Installation
### :bar_chart: R
Run the following in the R console to install the package and its dependencies:

```R
# install devtools if haven't got it already
install.packages("devtools")

# This also installs the package vtg
devtools::install_github(repo='iknl/vantage6-algorithms', ref='coxzph', subdir='models/coxzph/src')

# It is also a requirement to install the `coxph` package
devtools::install_github(repo='iknl/vantage6-algorithms', ref='coxph', subdir='models/coxph/src')

# This will become the following in the future (when the coxzph/coxph branch is merged)
devtools::install_github('iknl/vantage6-algorithms', subdir='models/coxzph/src')
devtools::install_github('iknl/vantage6-algorithms', subdir='models/coxph/src')
```

## :man_technologist: Examples
In order to run the following examples, you need to have prepared:
* A vantage6 server
* A user
* A collaboration with 3 organizations and 3 nodes

Additionally, each node should host and have configured the datasets `data_1.csv`, `data_2.csv`, `data_3.csv` which you can find in iknl/vantage6-algorithms/models/coxzph/src/data.

### :bar_chart: R
```R
rm(list=ls(all.names=T));set.seed(1234L);
library(vtg);library(vtg.coxzph);library(vtg.coxph);

setup.client <- function() {
  # Define parameters
  username <- 'admin'
  password <- 'password'
  host <- 'http://127.0.0.1:5000'
  api_path <- ''

  # Create the client
  client <- vtg::Client$new(host, api_path=api_path)
  client$authenticate(username, password)

  return(client)
}

# Create a client
client <- setup.client()

# Select a collaboration
client$setCollaborationId(1)

# Setup some variables for analysis... 
time='time';event='censor';transform='log';expl_vars=c("drug", "age"); time_col=c("censor");

# First need to extract analysis from CoxPH model. Assumed this is there. 
coxfit <- vtg.coxph::dcoxph(client, expl_vars = expl_vars, time_col = time_col, censor_col = censor_col)
# Run CoxZPH based of the coxfit
result <- vtg.coxzph::dcoxzph(client, fit = coxfit, time = time, event = event, transform = transform)
```

## :building_construction: Builds
This repository is automatically built into a Docker image and pushed to our Docker image registry `harbor2.vantage6.ai`.
If this is the `main` branch the image will be uploaded with the `latest` tag.

```
harbor2.vantage6.ai/algorithms/coxzph:latest
```

In case the `coxzph` branch is used the image is built and tagged with the shortened commit hash.

```
harbor2.vantage6.ai/algorithms/coxzph:COMMIT_HASH
```