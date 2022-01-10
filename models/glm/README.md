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

This algorithm is implemented in R, but with help of our R and Python wrappers you can also call the algorithm from Python.

The current implementation is validated for the following R family inputs: 
* gaussian(link = "identity"): gaussian regression
* binomial(link = "logit"): normal logistic regression
* poisson(link = "log"): poisson regression
* "rs.poi": custom glm relative survival model with poisson error
See the documentation and iknl/vantage6-algorithms/models/glm/src/validation/validation.R .

## Documentation 
Check "Technical Documentation - GLM" for technical details about the algorithm and more. (<- @TODO this should be a link to the .pdf)

## Builds
This repository is automatically built into a Docker image and pushed to our Docker image registry `harbor2.vantage6.ai`. 
If this is the `main` branch the image will be uploaded with the `latest` tag.

```
harbor2.vantage6.ai/algorithms/glm:latest
```

In case the `glm` branch is used the image is built and tagged with the shortened commit hash.

```
harbor2.vantage6.ai/algorithms/glm:COMMIT_HASH
```

## Installation
### R
Run the following in the R console to install the package and its dependencies:

```R
# This also installs the package vtg
devtools::install_github('iknl/vantage6-algorithms', subdir='models/glm/src')
```

## Run examples
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

# vtg.glm contains the function `dglm`.
result <- vtg.glm::dglm(client, formula = num_awards ~ prog + math, family='poisson', tol=1e-08, maxit=25)
```

### Python
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

### API
@TODO add a section about API calls (not sure if it should be at 'Run examples')

## Notes
1. Added 'as.GLM.R' to convert the result to a glm/lm object
    * Simply wrap the object with the as.GLM -> as.GLM(object) where 'object' is the final output (the trained model).
2. The as.GLM() function misses some outputs compared to the R built-in glm function:
    * AIC output set to 1, not properly implemented yet.
    * 'Deviance Residuals' printed by R's summary.glm(glm-output) is not included yet.
    * 'Number of Fisher Scoring iterations' printed by R's summary.glm(glm-output) is not included yet.
    * 'Signif. codes:  ... printed by R's summary.glm(glm-output) is not included yet.



