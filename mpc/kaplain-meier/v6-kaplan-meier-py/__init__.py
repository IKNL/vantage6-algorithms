import jwt
import os
import asyncio
import subprocess

from time import sleep
from typing import Any, Dict, Tuple, List
from pandas import DataFrame

from vantage6.common import info
from vantage6.client import ContainerClient

from tno.mpc.communication import Pool
from tno.mpc.protocols.kaplan_meier import Alice, Bob, Helper


WAIT = 4
RETRY = 10
WORKER_TYPES = {'event', 'groups'}

def main(client: ContainerClient, _, organizations: List[int]):
    """
    """

    # Retreive own IP and port so that we can send these to the child-
    # tasks
    # info('Retrieving own IP and port')
    #FIXME: we should extend container client and ENVIRONMENT vars, port
    # and IP should be profided. Also additional tooling should be
    # profided in order to simplify the retrievel of other parties ips
    # and ports.
    # my_info = _find_my_ip_and_port(client)

    # create tasks for the organizations at the server
    info("Dispatching worker tasks")
    tasks = client.create_new_task(
        input_={
            'method': 'worker',
        },
        organization_ids=organizations
    )

    info('exiting master container...')
    # info('waiting for restults...')

def RPC_worker(data: DataFrame):

    player = os.environ['player']
    if player == 'Alice':
        info('I am Alice...')
        alice()
    elif player == 'Bob':
        info('I am bob...')
        bob()
    elif player == 'Helper':
        info('I am Helper...')
        helper()


def alice():

    info('Alice worker initialization')
    _, _, all_results = _prework()

    info('Run script')
    cmd = [
        'python', '-u', '/app/v6-kaplan-meier-py/run.py',
        '-P', f'localhost:8888',
        '-P', f'{all_results[1]["node"]["ip"]}:{all_results[1]["port"]}',
        '-P', f'{all_results[2]["node"]["ip"]}:{all_results[2]["port"]}',
        '-I0',
        '-p', 'Alice',
        '--alice', f'{all_results[0]["node"]["ip"]}:{all_results[0]["port"]}',
        '--bob', f'{all_results[1]["node"]["ip"]}:{all_results[1]["port"]}'
    ]
    info(f'cmd = {cmd}')

    subprocess.run(cmd)
    return True

def bob():

    info('Group worker initialization')
    _, _, all_results = _prework()

    info('Run script')
    cmd = [
        'python', '-u', '/app/v6-kaplan-meier-py/run.py',
        '-P', f'{all_results[0]["node"]["ip"]}:{all_results[0]["port"]}',
        '-P', f'localhost:8888',
        '-P', f'{all_results[2]["node"]["ip"]}:{all_results[2]["port"]}',
        '-I1',
        '-p', 'Bob',
        '--alice', f'{all_results[0]["node"]["ip"]}:{all_results[0]["port"]}',
        '--bob', f'{all_results[1]["node"]["ip"]}:{all_results[1]["port"]}'
    ]
    info(f'cmd = {cmd}')
    subprocess.run(cmd)
    return True

def helper():

    info('Helper worker initialization')
    _, _, all_results = _prework()

    info('Run script')
    cmd = [
        'python', '-u', '/app/v6-kaplan-meier-py/run.py',
        '-P', f'{all_results[0]["node"]["ip"]}:{all_results[0]["port"]}',
        '-P', f'{all_results[1]["node"]["ip"]}:{all_results[1]["port"]}',
        '-P', f'localhost:8888',
        '-I2',
        '-p', 'Helper'
    ]

    info(f'cmd = {cmd}')
    subprocess.run(cmd, capture_output=True)
    return True


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
    info(f'others info {other_results}')

    return my_result, other_results, results

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