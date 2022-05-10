<h1 align="center">
  <br>
  <a href="https://vantage6.ai"><img src="https://github.com/IKNL/guidelines/blob/master/resources/logos/vantage6.png?raw=true" alt="vantage6" width="400"></a>
</h1>

<h3 align=center> A privacy preserving federated learning solution</h3>
<!-- [![CI](https://github.com/IKNL/v6-summary-py/actions/workflows/main.yml/badge.svg)](https://github.com/IKNL/v6-summary-py/actions/workflows/main.yml) -->

<h3 align="center">

[![Docker Image](https://github.com/IKNL/v6-summary-py/actions/workflows/main.yml/badge.svg)](https://github.com/IKNL/v6-summary-py/actions/workflows/main.yml)

</h3>
# Federated Summary

|:warning: priVAcy preserviNg federaTed leArninG infrastructurE for Secure Insight eXchange (VANTAGE6) |
|------------------|
| This algorithm is part of [VANTAGE6](https://github.com/IKNL/vantage6). A docker build of this algorithm can be obtained from harbor.vantage6.ai/algorithms/dsummary |

Algorithm that is inspired by the `Summary` function in R. It report the `Min`, `Q1`, `Mean`, `Median`, `Q3`, `Max` and number of `Nan` values per column from each `Node`.

## Possible Privacy Issues

🚨 Categorial column with only one category <br />
🚨 `Min` an `Max` for each column is reported <br />
🚨 Column names can be geussed, by trail and error

## Privacy Protection

✔️ If column names do not match nothing else is reported <br />
✔️ If dataset has less that 10 rows, no statistical analysis is performed <br />
✔️ Only statistical results `Min`, `Q1`, `Mean`, `Median`, `Q3`, `Max` and number of `Nan` values per column are reported.

## Usage
```python
from vantage6.client import Client
from pathlib import Path

# Create, athenticate to the vantage6-server
client = Client("http://127.0.0.1", 5000, "")
client.authenticate("frank@iknl.nl", "password")

# Setup the encryption module. When you *do* want to use encryption (which is
# managed at collaboration level) you enter the path to the private key file
# here. This is needed for encrypting/decrypting task input and their results
client.setup_encryption(None)

input_ = {
    # Flag to determine if we are triggering a `master` method or `RPC_`
    # method. This should be coherent with the "method" input.
    "master": True,

    # Name of the method to trigger. If you want to use a `master` process,
    # you should leave this at master
    "method": "master",

    # kwargs which are inserted into the algorithm
    "kwargs": {

        # The `columns` in the datasets you want to summarize and specify if
        # they are categorical ("category" or "c") or numeric ("numeric" or
        # "n")
        "columns": {
            "num_awards": "numeric",
            "prog": "category",
            "math": "n",
        },

        # Optionally, the organizations you want to include. They need to be
        # within the collaboration. By default all organizations in the
        # collaboration are included.
        "organizations_to_include": [1,2,3], # default: 'ALL'

        # Optionally, the subset you want to know the summary about. E.g. you only
        # want to include patients with a certain diagnose.
        "subset": {"diagnose": "cancer"}
    }
}

# Send the task to the central server
task = client.task.create(

    # This name is printed in the log files of the receiving party and can be
    # used to filter tasks on when it is retrieved
    name="Summary algorithm",

    # Docker image that contains the summary algorithm
    image="harbor2.vantage6.ai/testing/summary:latest",

    # Input we defined earlier
    input=input_,

    # Collaboration ID to which you want to send the task
    collaboration=1,

    # Organization ID(s) of the organization(s) that executes the task. Note
    # that in case of a `master` container only a single organization should be
    # specified as the master container will create the subtasks. See the
    # 'organizations_to_include' input parameter we defined earlier
    organizations=[2],

    # Human readable description which can be used for future reference
    description="This is an example algorithm call"
)

# Once the task has been send to the central server. It takes a while before
# the algorithm returns the values. One way to check if the results are ready
# is polling
print("Waiting for results")
task_id = task.get("id")
task_info = client.task.get(task_id)
while not task_info.get("complete"):
    task_info = client.task.get(task_id, include_results=True)
    print("Waiting for results")
    time.sleep(3)
print("Results are ready!")

# If the result is ready, we can pick it up. Since it is a master we only
# have to pickup a single result
result_info = client.result.get(task_info.get("results")[0].get("id"))
result = result_info["result"]
print(result)
```

## Test / Develop

You need to have Docker installed.

To Build (assuming you are in the project-directory):
```
docker build -t harbor.vantage6.ai/algorithms/summary .
```

To test/run locally the folder `local` is included in the repository. The following command mounts these files and sets the docker `ENVIROMENT_VARIABLE` `DATABASE_URI`.
```
docker run -e DATABASE_URI=/app/database.csv -v .\local\input.txt:/app/input.txt -v .\local\output.txt:/app/output.txt -v .\local\database.csv:/app/database.csv harbor.vantage6.ai/algorithms/summary
```
