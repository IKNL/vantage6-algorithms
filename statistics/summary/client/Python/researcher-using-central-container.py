""" Researcher (polling, no websocket but using central container)

Example on how the researcher should initialize a task without using
the central container. This means that the central part of the
algorithm needs to be executed on the machine of the researcher.

For simplicity this example also uses polling to obtain the results.
A more advanced example shows how to obtain the results using websockets

The researcher has to execute the following steps:
1) Authenticate to the central-server
2) Prepare the input for the algorithm
3) Post a new task to a collaboration on the central server
4) Wait for central container to finish (polling)
5) Obtain the results
"""
import time

from vantage6.client import Client

# 1. authenticate to the central server
client = Client(
    host="http://192.168.37.1",
    port=5000,
    path="/api"
)
client.setup_encryption(None)
client.authenticate("root", "admin")

# 2. Prepare input for the dsummary Docker image (algorithm)
input_ = {
    "method": "master",
    "args": [],
    "kwargs": {
        "decimal": ",",
        "seperator": ";",
        "columns": {
            "patient_id": "Int64",
            "age": "Int64",
            "weight": "float64",
            "stage": "category",
            "cat": "category",
            "hot_encoded": "Int64"
        }
    }
}

# 3. post the task to the server
task = client.post_task(
    name="summary",
    image="docker-registry.distributedlearning.ai/dsummary",
    collaboration_id=3,
    organization_ids=[3],  # specify where the central container should run!
    input_=input_
)

# 4. poll if central container is finished
task_id = task.get("id")
print(f"task id={task_id}")

task = client.request(f"task/{task_id}")
while not task.get("complete"):
    task = client.request(f"task/{task_id}")
    print("Waiting for results...")
    time.sleep(1)

# 5. obtain the finished results
results = client.get_results(task_id=task.get("id"))

# e.g. print the results per node
for result in results:
    node_id = result.get("node")
    print("-"*80)
    print(f"Results from node = {node_id}")
    print(result.get("result"))
