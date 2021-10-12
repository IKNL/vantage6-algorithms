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

# Create, athenticate and setup client
client = Client("http://127.0.0.1", 5000, "")
client.authenticate("frank@iknl.nl", "password")
client.setup_encryption(None)

# Define algorithm input
# include the columns you want to summarize, 
# and specify if they are categorical ("category" or "c") or numeric ("numeric" or "n")
input_ = {
    "master": True,
    "method":"master",
    "args": [],
    "kwargs": {
        "columns": {
            "num_awards": "numeric",
            "prog": "category",
            "math": "n"
        }        
    }
}

# Send the task to the central server
task = client.task.create(name="algo_testing-summary",
                          image="harbor2.vantage6.ai/testing/summary:latest",
                          input=input_,
                          collaboration=1, 
                          organizations=[2],
                          description=""
                          )

# Retrieve the results
print("Waiting for results")
task_id = task.get("id")
task_info = client.task.get(task_id)
while not task_info.get("complete"):
    task_info = client.task.get(task_id, include_results=True)
    print("Waiting for results")
    time.sleep(3)
print("Results are ready!")

result_info = client.result.get(task_info.get("results")[0].get("id"))
result = result_info["result"]
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
