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
import pandas as pd
import numpy as np
import threading
import ssl
import logging
import numpy as np
import numpy.typing as npt

from typing import Optional, List

import tno.mpc.communication.httphandlers
from tno.mpc.communication import Pool
from tno.mpc.protocols.kaplan_meier.player import Player
from tno.mpc.protocols.kaplan_meier import Alice, Bob, Helper
from tno.mpc.protocols.kaplan_meier.player import MPCProtocolMetadata

from .mpc import setup

#
# MONKEY PATCHES
#

# Alice needs to shutdown the HTTP server after its done
async def new_alice_start_protocol(self) -> None:
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
    await self.pool.shutdown()
    await self.run_mpyc()

Alice.start_protocol = new_alice_start_protocol

# Bob needs to shutdown after it received the last message
async def new_receive_share(self) -> None:
    encrypted_share = await self.receive_message(self.party_A, msg_id="share")
    await self.pool.shutdown()
    self._mpyc_data = await self.decrypt_share(encrypted_share)
    self._mpyc_factors = np.zeros((len(self._mpyc_data), 3), dtype=np.float64)

Bob.receive_share = new_receive_share

# Our setup does not use CLI arguments. Therefore we patch the setup
# module from MPyC and have to patch the mpc (=runtime) object in the
# tno module
async def new_run_mpyc(self) -> None:
    """
    Runs the Shamir secret sharing part of the protocol using the MPyC
    framework
    """
    async with self.mpc as mpc:
        assert len(mpc.parties) == 3, \
            "Number of parties should be 3"
        await self._start_mpyc()
        await self.obtain_secret_sharings()
        await self.secure_multivariate_log_rank_test()

Player.run_mpyc = new_run_mpyc



def new_player_init(self, identifier: str, parties: List[str],
                    index: int=1, ssl: bool=False,
                    output_file: bool=False, party_A: str = "Alice",
                    party_B: str = "Bob", helper: str = "Helper"
                    ) -> None:
    """
    Initializes player
    :param identifier: (unique) name of the player
    :param party_A: identifier of party Alice
    :param party_B: identifier of party Bob
    :param helper: identifier of the helper party
    """
    self._identifier = identifier
    self._party_A = party_A
    self._party_B = party_B
    self._helper = helper
    self.mpc_metadata = MPCProtocolMetadata()
    self.mpc(parties, index, ssl, output_file)
    self._logger = logging.getLogger(self._identifier)
    self._logger.setLevel(logging.DEBUG)
    logging.basicConfig(
        format="%(asctime)s - %(name)s - " "%(levelname)s - %(message)s"
    )

    self._mpyc_data = None
    self._mpyc_shares = None
    self._mpyc_factors = None
    self._mpyc_factors_shares = None
    self.statistic = None

Player.__init__ = new_player_init

# The http client uses a different listening port than the external port
# that is used
def new_http_client_init(self, pool, addr: str, port: int,
                         ssl_ctx: Optional[ssl.SSLContext]):
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


tno.mpc.communication.httphandlers.HTTPClient.__init__ = new_http_client_init

#
# KAPLAN MEIER
#

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
            player_instance = Alice(
                identifier=player,
                data=event_times,
                pool=pool,
            )
        elif player == "Bob":
            groups = test_data[["Group A", "Group B"]]
            player_instance = Bob(
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
