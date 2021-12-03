"""
Example usage for performing Kaplan-Meier analysis
Run three separate instances e.g.,
   $ ./script/example_usage.py -M3 -I0 -p Alice
   $ ./script/example_usage.py -M3 -I1 -p Bob
   $ ./script/example_usage.py -M3 -I2 -p Helper
All but the last argument are passed to MPyC.
"""

import argparse
import asyncio
from os import terminal_size
import time
import lifelines
import pandas as pd
import numpy as np
import aiohttp
import threading
import ssl

from typing import Optional

import tno.mpc.communication.httphandlers

from tno.mpc.communication import Pool

from tno.mpc.protocols.kaplan_meier import Alice, Bob, Helper

class Alice2(Alice):

    async def start_protocol(self) -> None:
        """
        Starts and runs the protocol
        """
        print('Alice2')
        await asyncio.gather(
            *[
                self.receive_paillier_scheme(),
                self.receive_number_of_groups(),
            ]
        )
        self.start_randomness_generation()
        await self.receive_encrypted_group_data()
        self.compute_hidden_table()
        self.compute_factors()
        self.re_randomise_ht()
        self.stop_randomness_generation()
        self.generate_share()
        await self.send_share()
        # time.sleep(10)
        await self.pool.shutdown()
        self._logger.error('start MPyC')
        await self.run_mpyc()
        self._logger.error('---****----')


async def new_receive_share(self) -> None:
    """
    Receive additive secret share produced by party Alice.
    """
    encrypted_share = await self.receive_message(self.party_A, msg_id="share")
    await self.pool.shutdown()
    self._logger.error('down')
    self._mpyc_data = await self.decrypt_share(encrypted_share)
    self._logger.error('a')
    self._mpyc_factors = np.zeros((len(self._mpyc_data), 3), dtype=np.float64)
    self._logger.error('c')


Bob.receive_share = new_receive_share

from mpyc.runtime import mpc

import tno.mpc.protocols.kaplan_meier.player

async def run_mpyc_2(self) -> None:
    """
    Runs the Shamir secret sharing part of the protocol using the MPyC
    framework
    """
    self._logger.error('run_mpyc_2')

    async with mpc:
        self._logger.error(mpc.parties)
        assert len(mpc.parties) == 3, "Number of parties should be 3"
        await self._start_mpyc()
        self._logger.error('-----')
        await self.obtain_secret_sharings()
        await self.secure_multivariate_log_rank_test()

tno.mpc.protocols.kaplan_meier.player.Player.run_mpyc = run_mpyc_2



class Bob2(Bob):

    async def start_protocol(self) -> None:
        """
        Starts and runs the protocol
        """
        print('bob2')
        await self.send_number_of_groups()
        loop = asyncio.get_event_loop()
        _, _, self.encrypted_data = await asyncio.gather(
            self.send_paillier_scheme(),
            self.send_number_of_groups(),
            loop.run_in_executor(None, self.encrypt, self.data),
        )
        self.stop_randomness_generation()
        await self.send_encrypted_data()
        await self.receive_share()
        # await self.pool.shutdown()
        self._logger.error('start MPyC')
        await self.run_mpyc()
        self._logger.error('---****----')

def new_http_client_init(
    self,
    pool,
    addr: str,
    port: int,
    ssl_ctx: Optional[ssl.SSLContext],
):
    """
    Initalizes an HTTP client instance
    :param pool: the communication pool to use
    :param addr: the address of the client
    :param port: the port of the client
    :param ssl_ctx: an optional ssl context
    :raise AttributeError: raised when the provided pool has no assigned http server.
    """
    self.pool = pool
    self.addr = addr
    self.port = port
    self.ssl_ctx = ssl_ctx
    if self.pool.http_server is None:
        raise AttributeError("No HTTP Server initialized (yet).")
    # self.session
    cookies = {"server_port": str(self.pool.external_port)}
    if self.pool.loop.is_running():
        self.pool.loop.create_task(self._create_client_session(cookies))
    else:
        self.pool.loop.run_until_complete(self._create_client_session(cookies))
    self.msg_send_counter = 0
    self.total_bytes_sent = 0
    self.msg_recv_counter = 0
    self.send_lock = threading.Lock()
    self.recv_lock = threading.Lock()
    self.buffer = {}

# monkey patch
tno.mpc.communication.httphandlers.HTTPClient.__init__ = new_http_client_init




def parse_args():
   parser = argparse.ArgumentParser()
   parser.add_argument(
       "-p", "--player", help="Name of the sending player", type=str, required=True
   )
   parser.add_argument(
       '-a', '--alice', help="Alice address", type=str, required=False
   )
   parser.add_argument(
       '-b', '--bob', help="Bob address", type=str, required=False
   )
   parser.add_argument(
       '-q', '--port', help="internal port", type=int, required=False, default=8888
   )
   args = parser.parse_args()
   return args


async def main(player_instance):
   await player_instance.start_protocol()


if __name__ == "__main__":
   # Parse arguments and acquire configuration parameters
   args = parse_args()
   player = args.player

   if player in ['Alice', 'Bob']:
        alice_ip, alice_port = args.alice.split(':')
        bob_ip, bob_port = args.bob.split(':')
        parties = {
            "Alice": {"address": alice_ip, "port": alice_port},
            "Bob": {"address": bob_ip, "port": bob_port},
        }

        test_data = pd.DataFrame(
            {
                "time": [3, 5, 6, 8, 10, 14, 14, 18, 20, 22, 30, 30],
                "event": [1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1],
                "Group A": [1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0],
                "Group B": [0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1],
            }
        )

        port = parties[player]["port"]
        del parties[player]

        pool = Pool()
        if player == 'Alice':
            pool.external_port = alice_port
        elif player == 'Bob':
            pool.external_port = bob_port

        pool.add_http_server(port=args.port)


        for name, party in parties.items():
            assert "address" in party
            pool.add_http_client(
                name, party["address"], port=party["port"] if "port" in party else 80
                # name, party["address"], port=8888 if "port" in party else 80
            )  # default port=80
        if player == "Alice":
            event_times = test_data[["time", "event"]]
            player_instance = Alice2(
                identifier=player,
                data=event_times,
                pool=pool,
            )
        elif player == "Bob":
            groups = test_data[["Group A", "Group B"]]
            player_instance = Bob2(
                identifier=player,
                data=groups,
                pool=pool,
            )

   elif player == "Helper":
       player_instance = Helper(player)
   else:
       raise ValueError(f"Unknown player was provided: '{player}'")

   loop = asyncio.get_event_loop()
   loop.run_until_complete(main(player_instance))

   print("-" * 32)
   print(player_instance.statistic)
   print("-" * 32)

#    # Validate results
#    event_times = test_data[["time", "event"]]
#    groups = test_data[["Group A", "Group B"]]
#    print(
#        lifelines.statistics.multivariate_logrank_test(
#            event_times["time"], groups["Group B"], event_times["event"]
#        )
#    )
#    print("-" * 32)