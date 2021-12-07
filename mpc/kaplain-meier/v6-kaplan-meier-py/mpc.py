"""Module to setup the mpc module runtime."""
import logging
import sys
import importlib
import os
import mpyc

# import mpyc.secgroups
import mpyc.random
import mpyc.statistics
import mpyc.seclists

from typing import List

from mpyc import sectypes
from mpyc import asyncoro
from mpyc.runtime import Runtime, Party


def setup(parties:List[str], index:int, ssl:bool=False,
          output_file:bool=False) -> Runtime:
    """Create MPyC runtime

    Parameters
    ----------
    parties : List[str]
        use addr=host:port per party
    index : int
        set index of this local party to i, 0<=i<m
    ssl : bool, optional
        enable SSL connections, by default False
    output_file : bool, optional
        append output for parties i>0 to party{m}_{i}.log, by default False

    Returns
    -------
    Runtime
        MPyC runtime object
    """
    logging.basicConfig(format='{asctime} {message}', style='{',
                        level=logging.INFO, stream=sys.stdout)

    logging.info('Patched MPC setup')
    if not importlib.util.find_spec('gmpy2'):
        # gmpy2 package not available
        logging.info('Install package gmpy2 for better performance.')

    env_mix32_64bit = os.getenv('MPYC_MIX32_64BIT') == '1'  # check if MPYC_MIX32_64BIT is set
    if env_mix32_64bit:
        logging.info('Mix of parties on 32-bit and 64-bit platforms enabled.')
        from hashlib import sha1

        def hop(a):
            """Simple and portable pseudorandom program counter hop for Python 3.6+.
            Compatible across all (mixes of) 32-bit and 64-bit Python 3.6+ versions. Let's
            you run MPyC with some parties on 64-bit platforms and others on 32-bit platforms.
            Useful when working with standard 64-bit installations on Linux/MacOS/Windows and
            installations currently restricted to 32-bit such as pypy3 on Windows and Python on
            Raspberry Pi OS.
            """
            return int.from_bytes(sha1(str(a).encode()).digest()[:8], 'little', signed=True)
        asyncoro._hop = hop

    addresses = []
    for party in parties:
        host, *port_suffix = party.rsplit(':', maxsplit=1)
        port = ' '.join(port_suffix)
        addresses.append((host, port))

    formatted_parties: List[Party] = []
    pid:int = index
    for i, (host, port) in enumerate(addresses):
        port = int(port)
        formatted_parties.append(Party(i, host, port))
    m = len(formatted_parties)

    class Options:

        def __init__(self, **kwargs):
            for label in kwargs:
                setattr(self, label, kwargs[label])

    options = Options(
        threshold = (m-1)//2,
        ssl = ssl,
        output_file = output_file,
        bit_length=32,
        sec_param=30,
        no_log=False,
        no_async=False,
        no_barrier=False,
        no_gmpy2=False,
        no_prss=False,
        mix32_64bit=env_mix32_64bit,
        output_windows=False,
        f=''
    )

    rt = Runtime(pid, formatted_parties, options)
    sectypes.runtime = rt
    asyncoro.runtime = rt
    # mpyc.secgroups.runtime = rt
    mpyc.random.runtime = rt
    mpyc.statistics.runtime = rt
    mpyc.seclists.runtime = rt
    logging.info('hi')
    logging.info(rt)
    logging.info(rt.pid)

    return rt

mpc = setup