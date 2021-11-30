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
import lifelines
import pandas as pd

from tno.mpc.communication import Pool

from tno.mpc.protocols.kaplan_meier import Alice, Bob, Helper


def parse_args():
   parser = argparse.ArgumentParser()
   parser.add_argument(
       "-p", "--player", help="Name of the sending player", type=str, required=True
   )
   args = parser.parse_args()
   return args


async def main(player_instance):
   await player_instance.start_protocol()


if __name__ == "__main__":
   # Parse arguments and acquire configuration parameters
   args = parse_args()
   player = args.player
   parties = {
       "Alice": {"address": "127.0.0.1", "port": 8080},
       "Bob": {"address": "127.0.0.1", "port": 8081},
   }

   test_data = pd.DataFrame(
       {
           "time": [3, 5, 6, 8, 10, 14, 14, 18, 20, 22, 30, 30],
           "event": [1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1],
           "Group A": [1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0],
           "Group B": [0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1],
       }
   )

   if player in parties.keys():
       port = parties[player]["port"]
       del parties[player]

       pool = Pool()
       pool.add_http_server(port=port)
       for name, party in parties.items():
           assert "address" in party
           pool.add_http_client(
               name, party["address"], port=party["port"] if "port" in party else 80
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

   # Validate results
   event_times = test_data[["time", "event"]]
   groups = test_data[["Group A", "Group B"]]
   print(
       lifelines.statistics.multivariate_logrank_test(
           event_times["time"], groups["Group B"], event_times["event"]
       )
   )
   print("-" * 32)