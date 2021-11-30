import jwt
import os
import asyncio
import subprocess

from time import sleep
from typing import Any, Dict, Tuple
from pandas import DataFrame

from vantage6.common import info
from vantage6.client import ContainerClient

from tno.mpc.communication import Pool
from tno.mpc.protocols.kaplan_meier import Alice, Bob, Helper


WAIT = 4
RETRY = 10
WORKER_TYPES = {'event', 'groups'}

def main(client: ContainerClient, _, g_organization: int,
         e_organization: int, h_organization: int):
    """
    """

    # Retreive own IP and port so that we can send these to the child-
    # tasks
    info('Retrieving own IP and port')
    #FIXME: we should extend container client and ENVIRONMENT vars, port
    # and IP should be profided. Also additional tooling should be
    # profided in order to simplify the retrievel of other parties ips
    # and ports.
    my_info = _find_my_ip_and_port(client)

    # create tasks for the organizations at the server
    info("Dispatching worker tasks")
    event_worker = client.create_new_task(
        input_={
            'method': 'group_worker',
            'kwargs': {'parent': my_info}
        },
        organization_ids=[g_organization]
    )

    group_worker = client.create_new_task(
        input_={
            'method': 'sensor_worker',
            'kwargs': {'parent': my_info}
        },
        organization_ids=[e_organization]
    )

    group_worker = client.create_new_task(
        input_={
            'method': 'helper_worker',
            'kwargs': {'parent': my_info}
        },
        organization_ids=[h_organization]
    )

    info('waiting for restults')

def RPC_group_worker(data: DataFrame, parent: Tuple[str, int]):
    """A.K.A. BOB"""

    # obtain ip and port from party
    info('Group worker initialization')
    #FIXME: this should happen in the wrapper..
    client = _temp_fix_client()

    task_id = _find_my_task_id(client)
    organization_id = _find_my_organization_id(client)

    info('Fetch other parties ips and ports')
    # FIXME: I abused the _await_port_numbers to check if the port
    # numbers are already available.
    results = _await_port_numbers(client, task_id)
    results = client.request(f"task/{task_id}/result")
    assert len(results) == 3, f"There are {len(results)} workers?!"
    other_results = []
    for result in results:
        if result['organization'] != organization_id:
            other_results.append(result)
        else:
            my_result = result

    process = subprocess.Popen([
        'python','/app/v6-kaplan-meier-py/run.py',
        f'-P {my_result["node"]["ip"]}:{my_result["port"]}',
        f'-P {other_results[0]["node"]["ip"]}:{other_results[0]["node"]["ip"]}',
        f'-P {other_results[1]["node"]["ip"]}:{other_results[1]["node"]["ip"]}',
        '-I0'
    ])

import subprocess
process = subprocess.run([
    'python','v6-kaplan-meier-py/run.py',
    f'-P', 'localhost:8080',
    f'-P', 'localhost:8081',
    f'-P', 'localhost:8082',
    '-I0',
    '-p', 'Alice'
])

import subprocess
process = subprocess.run([
    'python','v6-kaplan-meier-py/run.py',
    f'-P', 'localhost:8080',
    f'-P', 'localhost:8081',
    f'-P', 'localhost:8082',
    '-I1',
    '-p', 'Bob'
])

import subprocess
process = subprocess.run([
    'python','v6-kaplan-meier-py/run.py',
    f'-P', 'localhost:8080',
    f'-P', 'localhost:8081',
    f'-P', 'localhost:8082',
    '-I2',
    '-p', 'Helper'
])





def RPC_event_worker(data: DataFrame, parent: Tuple[str, int]):

    info('Event worker initialization')
    info('Setup socket connection to parent container')

def RPC_helper_worker(data: DataFrame, parent: Tuple[str, int]):
    pass



def _temp_fix_client():
    token_file = os.environ["TOKEN_FILE"]
    info(f"Reading token file '{token_file}'")
    with open(token_file) as fp:
        token = fp.read().strip()

    return ContainerClient(token)

def _find_my_task_id(client):
    id_ = jwt.decode(client._access_token, verify=False)['identity']
    return id_.get('task_id')

def _find_my_organization_id(client):
    id_ = jwt.decode(client._access_token, verify=False)['identity']
    return id_.get('organization_id')

def _find_my_ip_and_port(client):
    own_id =  _find_my_task_id(client)
    tasks = client.request(f'task/{own_id}/result')
    assert len(tasks) == 1, "Multiple master tasks?"
    result = next(tasks)
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