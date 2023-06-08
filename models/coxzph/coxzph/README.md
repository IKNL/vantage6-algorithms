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

[![GLM Build](https://github.com/IKNL/vantage6-algorithms/actions/workflows/build-glm.yaml/badge.svg)](https://github.com/IKNL/vantage6-algorithms/actions/workflows/build-glm.yaml)

-----------------------------------------------------------------------------------------------------

## :handshake: Introduction
This repository includes an implementation of the federated Generalized Linear Model (GLM) for horizontally partitioned data.

Generalized Linear Models estimate regression models for outcomes following exponential distributions. The GLM generalizes linear regression by allowing the linear model to be related to the response variable via a link function and by allowing the magnitude of the variance of each measurement to be a function of its predicted value.

The algorithm is implemented in R and can be easily used in R as well. However, with the help of our wrapper, you can also call the algorithm from Python.

## :computer: Installation
### :bar_chart: R
Run the following in the R console to install the package and its dependencies:

```R
# install devtools if haven't got it already
install.packages("devtools")

# This also installs the package vtg
devtools::install_github(repo='iknl/vantage6-algorithms', ref='glm', subdir='models/glm/src')

# This will become the following in the future (when the glm branch is merged)
devtools::install_github('iknl/vantage6-algorithms', subdir='models/glm/src')
```

## :man_technologist: Examples
In order to run the following examples, you need to have prepared:
* A vantage6 server
* A user
* A collaboration with 3 organizations and 3 nodes

Additionally, each node should host and have configured the datasets `data_user1.csv`, `data_user2.csv`, `data_user3.csv` which you can find in iknl/vantage6-algorithms/models/glm/src/data.

### :bar_chart: R
```R
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

# Get a list of available collaborations
print( client$getCollaborations() )

# Should output something like this:
#   id     name
# 1  1 ZEPPELIN
# 2  2 PIPELINE

# Select a collaboration
client$setCollaborationId(1)

# First need to extract analysis from CoxPH model. Assumed this is there. 
result <- vtg.glm::dglm(client, formula = num_awards ~ prog + math, family='poisson', tol=1e-08, maxit=25)
```

### :snake: Python
```Python
import time
from vantage6.client import Client

username = 'username@example.com'
password = 'password'
host = 'https://address-to-vantage6-server.domain'
port = 5000 # specify the correct port, 5000 is an example
api_path = '' # specify the correct path

client = Client(host, port, api_path)
client.authenticate(username, password)
client.setup_encryption(None)

# Get a list of available collaborations
print(client.collaboration.list(fields=['id', 'name']))

# Should output something like this:
# [{'id': 1, 'name': 'ZEPPELIN'}, {'id': 2, 'name': 'PIPELINE'}]

# Select a collaboration
COLLABORATION_ID = 1 # specify the correct id

# Get all organizations in the collaboration
ORGANIZATION_IDS = [i['id'] for i in client.collaboration.get(COLLABORATION_ID).get('organizations')]

# Prepare task input
input_ = {'master': True,
          'method': 'dglm',
          'args': [],
          'kwargs': {'formula': 'num_awards ~ prog + math',
                     'types': {'prog': {'type': 'factor',
                                        'levels': ['General','Vocational','Academic']}},
                     'family': 'poisson',
                     'tol': 1e-08,
                     'maxit': 25
                    },
          'output_format': 'json'
          }

# Sending the analysis task to the server
my_task = client.task.create(collaboration=COLLABORATION_ID,
                             organizations=[ORGANIZATION_IDS[0]],
                             name='GLM-example',
                             description='Testing the GLM algorithm.',
                             image='harbor2.vantage6.ai/algorithms/glm:latest',
                             input=input_,
                             data_format='json'
                            )

task_id = my_task.get('id')
print(f'Task id: {task_id}')

# Polling for results
task_info = client.task.get(task_id)
while not task_info.get("complete"):
    task_info = client.task.get(task_id, include_results=True)
    time.sleep(30) #sec
    print('Waiting for results..')
print('Results are ready!')

# Retrieve result
result = client.result.from_task(task_id)[0].get('result')
```
### :keyboard: API
@TODO add a section about API calls (not sure if it should be at 'Run examples')


## :books: Documentation
Check "Technical Documentation - GLM" for technical details about the algorithm as well as the accompanying [PDF](./manual/main.pdf).

## :building_construction: Builds
This repository is automatically built into a Docker image and pushed to our Docker image registry `harbor2.vantage6.ai`.
If this is the `main` branch the image will be uploaded with the `latest` tag.

```
harbor2.vantage6.ai/algorithms/glm:latest
```

In case the `glm` branch is used the image is built and tagged with the shortened commit hash.

```
harbor2.vantage6.ai/algorithms/glm:COMMIT_HASH
```



## :balance_scale: Validation
The code used for the validation of the algorithm (i.e., comparing its performance against its centralized counterpart) can be found in [`./src/validation`](./src/validation). The `R` notebook `validation.ipynb` contains the complete procedure, while the `Python` script `create_data.py` allows generating the data needed.

So far, the current implementation is validated for the following model families:
* `gaussian(link = "identity")`: Linear regression
* `poisson(link = "log")`: Poisson regression
* `binomial(link = "logit")`: Logistic regression

## :spiral_notepad: Notes
1. Added `as.GLM.R` to convert the result to a `glm/lm` object
    * Simply wrap the object with the `as.GLM` -> `as.GLM(object)` where `object` is the final output (i.e., the trained model).
2. The `as.GLM()` function misses some outputs compared to the `R` built-in `glm` function:
    * For now, `AIC` output is set to 1. It isn't properly implemented yet.
    * `Deviance Residuals` printed by `R`'s `summary.glm(glm-output)` are not included yet.
    * `Number of Fisher Scoring iterations` printed by `R`'s `summary.glm(glm-output)` is not included yet.
    * `Signif. codes:  ...` printed by `R`'s `summary.glm(glm-output)` are not included yet.

## :black_nib: References
If you are using this algorithm, please cite the accompanying paper as follows:
> * Matteo Cellamare, Anna J. van Gestel, Hasan Alradhi, Frank Martin, Arturo Moncada-Torres, "A Federated Generalized Linear Model for Privacy-Preserving Analysis". *Algorithms*, vol. 15, no. 7, 2022, p. 1-12. [[BibTeX](https://arturomoncadatorres.com/bibtex/cellamare2022federated.txt), [PDF (Open Access)](https://mdpi.com/1999-4893/15/7/243/)]

Additionally, if you are using this algorithm in [vantage6](https://github.com/IKNL/vantage6), please cite the following papers as well:
> * Arturo Moncada-Torres, Frank Martin, Melle Sieswerda, Johan van Soest, Gijs Gelijnse. VANTAGE6: an open source priVAcy preserviNg federaTed leArninG infrastructurE for Secure Insight eXchange. AMIA Annual Symposium Proceedings, 2020, p. 870-877. [[BibTeX](https://arturomoncadatorres.com/bibtex/moncada-torres2020vantage6.txt), [PDF](https://vantage6.ai/vantage6/)]
> * D. Smits\*, B. van Beusekom\*, F. Martin, L. Veen, G. Geleijnse, A. Moncada-Torres, An Improved Infrastructure for Privacy-Preserving Analysis of Patient Data, Proceedings of the International Conference of Informatics, Management, and Technology in Healthcare (ICIMTH), vol. 25, 2022, p. 144-147. [[BibTeX](https://arturomoncadatorres.com/bibtex/smits2022improved.txt), [PDF](https://ebooks.iospress.nl/volumearticle/60190)]
