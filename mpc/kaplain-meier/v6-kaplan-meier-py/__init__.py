# monkey patch first
import pandas as pd
from .patcher import monkey_patch
monkey_patch()

import jwt
import os
import time
import subprocess
import asyncio

from time import sleep
from typing import Any, Dict, Tuple

from vantage6.common import info
from vantage6.client import ContainerClient

from tno.mpc.communication import Pool
from tno.mpc.protocols.kaplan_meier import Alice, Bob, Helper

from .mpc import setup

INTERNAL_PORT = 8888
WAIT = 4
RETRY = 10
WORKER_TYPES = {'event', 'groups'}

def main(client: ContainerClient, _, alice: int, bob: int, helper: int):
    """
    """
    # create tasks for the organizations at the server
    info("Dispatching worker tasks")
    task = client.create_new_task(
        input_={
            'method': 'worker',
        },
        organization_ids=[alice, bob, helper]
    )

    info("Waiting for results")
    task_id = task.get("id")
    task = client.get_task(task_id)
    i = 1
    while not task.get("complete") and i < 180:
        task = client.get_task(task_id)
        info(f"Waiting for results {i}")
        time.sleep(1)
        i += 1

    # Once we now the partials are complete, we can collect them.
    info("Obtaining results")
    results = client.get_results(task_id=task_id)

    info('exiting master container...')

    # We only need the result of a single party
    return results.pop()

def RPC_worker(data: pd.DataFrame):

    # Additional algorithm variable need to be set in the node
    # configuration
    player = os.environ['player'].capitalize()
    assert player in ['Alice', 'Bob', 'Helper'], \
        f"Unknown player provided '{player}'"
    info(f'I am player \'{player}\'')

    # Wait, and obtain ips and ports of all other parties
    addresses = _prework()
    info(f'Adresses ready: {addresses}')

    # Result order. It is assumed that the first results belongs to
    # Alice, second to Bob and the third to the Helper. This works
    # because the master container determines the order.
    my_idx = {'Alice': 0, 'Bob': 1, 'Helper': 2}[player]

    # MPyC party configuration. Vantage6 algorithms can *only* listen
    # to port 8888. External port != internal port.
    parties = [f'{a["ip"]}:{a["port"]}' for a in addresses]
    parties[my_idx] = 'localhost:8888'
    info(f'MPyC party configuration: {parties}')

    # Only alice and bob participate in the initial part of computing
    # the kaplan-meier curve
    if player in ['Alice', 'Bob']:

        pool = Pool()
        # This works because we patched the pool class from TNO
        is_alice = player == 'Alice'
        my_idx, other_idx = (0, 1) if is_alice else (1, 0)
        other_name = 'Bob' if is_alice else 'Alice'

        my_external_port = addresses[my_idx]['port']
        other_port = addresses[other_idx]['port']
        other_ip = addresses[other_idx]['ip']

        pool.external_port = my_external_port
        pool.add_http_server(port=INTERNAL_PORT)
        pool.add_http_client(other_name, other_ip, port=other_port)


        PlayerClass = Alice if is_alice else Bob
        player_instance = PlayerClass(identifier=player, data=data,
                                      pool=pool, parties=parties,
                                      index=my_idx)
    else:
        player_instance = Helper(player, parties=parties, index=my_idx)

    # start the loop
    info('Starting the analysis')
    loop = asyncio.get_event_loop()
    loop.run_until_complete(start(player_instance))

    info('Collected results, sending to the main')
    return player_instance.statistic


async def start(player_instance):
   await player_instance.start_protocol()


def _prework():

    client = _temp_fix_client()

    task_id = _find_my_task_id(client)
    organization_id = _find_my_organization_id(client)

    info('Fetch other parties ips and ports')
    results = _await_port_numbers(client, task_id)
    info(' -> Port numbers available ...')
    results = client.request(f"task/{task_id}/result")
    results = sorted(results, key=lambda d: d['id'])
    assert len(results) == 3, f"There are {len(results)} workers?!"
    other_results = []
    for result in results:
        if result['organization'] != organization_id:
            other_results.append(result)
        else:
            my_result = result
    info(f'my info: {my_result}')
    info(f'Others info: {other_results}')
    info('Extracting ip/ports')

    return [{'ip': r["node"]["ip"], 'port': r['port']} for r in results]

def _temp_fix_client():
    token_file = os.environ["TOKEN_FILE"]
    info(f"Reading token file '{token_file}'")
    with open(token_file) as fp:
        token = fp.read().strip()
    host = os.environ["HOST"]
    port = os.environ["PORT"]
    api_path = os.environ["API_PATH"]
    return ContainerClient(
        token=token,
        port=port,
        host=host,
        path=api_path
    )

def _find_my_task_id(client):
    id_ = jwt.decode(client._access_token, verify=False)['identity']
    return id_.get('task_id')

def _find_my_organization_id(client):
    id_ = jwt.decode(client._access_token, verify=False)['identity']
    return id_.get('organization_id')

def _find_my_ip_and_port(client):
    own_id =  _find_my_task_id(client)
    tasks: list = client.request(f'task/{own_id}/result')
    assert len(tasks) == 1, "Multiple master tasks?"
    result = tasks.pop()
    return (result['node']['ip'], result['port'])

def _await_port_numbers(client, task_id):
    result_objects = client.get_other_node_ip_and_port(task_id=task_id)

    c = 0
    while not _are_ports_available(result_objects):
        if c >= RETRY:
            raise Exception('Retried too many times')

        info('Polling results for port numbers...')
        result_objects = client.get_other_node_ip_and_port(task_id=task_id)
        c += 1
        sleep(WAIT)

    return result_objects


def _are_ports_available(result_objects):
    for r in result_objects:
        _, port = _get_address_from_result(r)
        if not port:
            return False

    return True

def _get_address_from_result(result: Dict[str, Any]) -> Tuple[str, int]:
    address = result['ip']
    port = result['port']

    return address, port



# import subprocess
# process = subprocess.Popen([
#     'python','v6-kaplan-meier-py/run.py',
#     f'-P', 'localhost:8080',
#     f'-P', 'localhost:8081',
#     f'-P', 'localhost:8082',
#     '-I0',
#     '-p', 'Alice',
#     '--alice', 'localhost:8080',
#     '--bob', 'localhost:8081',
#     '--port', '8080'
# ])

# import subprocess
# process = subprocess.Popen([
#     'python','v6-kaplan-meier-py/run.py',
#     f'-P', 'localhost:8080',
#     f'-P', 'localhost:8081',
#     f'-P', 'localhost:8082',
#     '-I1',
#     '-p', 'Bob',
#     '--alice', 'localhost:8080',
#     '--bob', 'localhost:8081',
#     '--port', '8081'
# ])

# import subprocess
# process = subprocess.Popen([
#     'python','v6-kaplan-meier-py/run.py',
#     f'-P', 'localhost:8080',
#     f'-P', 'localhost:8081',
#     f'-P', 'localhost:8082',
#     '-I2',
#     '-p', 'Helper'
# ])
