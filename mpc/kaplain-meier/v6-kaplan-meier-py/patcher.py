import asyncio
import numpy as np
import threading
import ssl
import logging
import numpy as np
import tno.mpc.communication.httphandlers
import tno.mpc.protocols.kaplan_meier.player

from functools import reduce
from typing import Optional, List, Tuple, Union, Sequence
from scipy.stats import chi2
from lifelines.statistics import StatisticalResult

from tno.mpc.protocols.kaplan_meier.player import Player
from tno.mpc.protocols.kaplan_meier import Alice, Bob
from tno.mpc.mpyc.matrix_inverse import matrix_inverse
from tno.mpc.encryption_schemes.utils import FixedPoint
from mpyc.sectypes import SecureFixedPoint
from tno.mpc.protocols.kaplan_meier.player import MPCProtocolMetadata

from .mpc import setup


#
# MONKEY PATCHES
#
def monkey_patch():
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
        self._logger.info('new_run_mpyc')
        async with self.mpc as mpc:

            self._logger.info(mpc)
            self._logger.info(mpc.pid)
            self._logger.info(mpc.parties)
            assert len(mpc.parties) == 3, \
                "Number of parties should be 3"
            await self._start_mpyc()
            await self.obtain_secret_sharings()
            await self.secure_multivariate_log_rank_test()

    Player.run_mpyc = new_run_mpyc

    # reference to MPyC fixed
    async def _new_start_mpyc(self) -> None:
        """
        Start MPyC and configure data parties.
        """
        self.mpc_metadata.secfxp = self.mpc.SecFxp(l=64, f=32)
        self._logger.info(f"In MPyC, you are player {self.mpc.pid}")
        self._logger.info(f"These are the other players: {self.mpc.parties}")
        data_parties = await self.mpc.transfer(self.identifier != self.helper)
        self.mpc_metadata.data_parties = [_ for _ in self.mpc.parties if data_parties[_.pid]]
        self._logger.info(
            f"These are the data_parties: {self.mpc_metadata.data_parties}"
        )

    Player._start_mpyc = _new_start_mpyc

    async def _new_request_format_data(
        self, dataframe  # type: ignore
    ) -> Tuple[int, int]:
        """
        Method to determine the data format of the dataframe.
        The first data owner determines the data format (rows x cols).

        :param dataframe: the dataframe to determine data format of
        :raise ValueError: raised when data_parties metadata is not configured
        :return: the format of the dataframe (rows, columns)
        """
        if self.mpc_metadata.data_parties is None:
            raise ValueError("data parties metadata is not set (yet)")
        if self.mpc.pid == self.mpc_metadata.data_parties[0].pid:
            assert (
                dataframe is not None
            ), f"Party {self.mpc.pid} is missing some important data."
            rows, columns = (
                dataframe.shape[0],
                dataframe.shape[1],
            )
        else:
            rows, columns = 0, 0
        rows, columns = await self.mpc.transfer(
            (rows, columns), senders=self.mpc_metadata.data_parties[0].pid
        )
        return rows, columns

    Player._request_format_data = _new_request_format_data

    async def _new_extract_and_convert_data_cols_from_np(
        self,
        dataframe,  # type: ignore
        typer: type,
    ) -> List[List[Union[int, float]]]:
        """
        Extract the columns of a numpy dataframe and return them in a list.
        The elements of the returned lists are converted to type typer.

        Converting the type of the elements is particularly helpful if the
        elements are to be used with MPyC; MPyC SecureNumber objects expect
        type None, int, float, or finite field element. In particular, MPyC
        does not know how to deal with the types that numpy associates to the
        elements of a ndarray.

        :param dataframe: the dataframe to extract data from
        :param typer: the expected type in the dataframe
        :raise ValueError: raised when data_parties metadata is not configured
          or when data is missing
        :return: the extracted data columns
        """
        if self.mpc_metadata.data_parties is None:
            raise ValueError("data parties metadata is not set (yet)")
        rows, columns = await self._request_format_data(dataframe)
        if self.mpc.pid in [_.pid for _ in self.mpc_metadata.data_parties]:
            if dataframe is None:
                raise ValueError(f"Party {self.mpc.pid} is missing some important data.")
            return [
                list(map(typer, dataframe[..., i])) for i in range(dataframe.shape[1])
            ]
        else:
            return [[typer(0)] * rows for _ in range(columns)]
    Player._extract_and_convert_data_cols_from_np = \
        _new_extract_and_convert_data_cols_from_np

    async def _new_reshare_dataframes(
        self,
        dataframe,  # type: ignore
        typer: type = float,
    ):
        """
        Re-share (in MPyC) the additively-shared inputs of the
        dataframe that is additively shared over the data owners.

        :param dataframe: the dataframe to reshare
        :param typer: the expected type in the dataframe
        :raise ValueError: raised when secfxp is not configured
        :return: Shamir secret sharing
        """
        if self.mpc_metadata.secfxp is None:
            raise ValueError("SecFxp is not configured (yet).")
        data_columns = await self._extract_and_convert_data_cols_from_np(
            dataframe, typer
        )
        shares = [
            reduce(
                self.mpc.vector_add,
                self.mpc.input(
                    list(map(lambda x: self.mpc_metadata.secfxp(x, integral=False), _))
                ),
            )
            for _ in data_columns
        ]
        return shares

    Player._reshare_dataframes = _new_reshare_dataframes

    async def _new_secure_multivariate_logrank_test(
        self,
        dev_factors: Sequence[SecureFixedPoint],
        var_factors: Sequence[SecureFixedPoint],
        var_factors_2: Sequence[SecureFixedPoint],
        deaths_array: Sequence[Sequence[SecureFixedPoint]],
        at_risk_array: Sequence[Sequence[SecureFixedPoint]],
    ) -> StatisticalResult:
        """
        Computes the logrank statistics for the given input.

        :param dev_factors: The j-th element of this list indicates
            the quantity (total number of deaths) / (total number of
            patients at risk) at the j-th distinct event time.
        :param var_factors: The j-th element of this list indicates
            the quantity (total number of deaths) * (total number at risk -
            total number of deaths) / (total number at risk ** 2 *
            (total number at risk - 1)) at the j-th distinct event time.
        :param var_factors_2: The j-th element of this list indicates
            the quantity var_factors * (total number at risk) at the j-th
            distinct event time.
        :param deaths_array: list that contains one list per patient
            category. The j-th element of the i-th list indicates the
            number of patients in category i that died at the j-th distinct
            event time.
        :param at_risk_array: list that contains one list per patient
            category. The j-th element of the i-th list indicates the
            number of patients in category i that are at risk at the j-th
            distinct event time.
        :raise ValueError: raised when secfxp is not configured
        :return: logrank statistics.
        """
        if self.mpc_metadata.secfxp is None:
            raise ValueError("SecFxp is not configured (yet).")
        nr_groups = len(at_risk_array)
        nr_comparisons = nr_groups - 1
        secfxp = self.mpc_metadata.secfxp
        devs: List[SecureFixedPoint] = [secfxp(None)] * nr_comparisons
        pre_vars: List[List[SecureFixedPoint]] = [
            [secfxp(None)] * len(at_risk_array[0]) for _ in range(nr_comparisons)
        ]
        neg_pre_vars: List[List[SecureFixedPoint]] = [
            [secfxp(None)] * len(at_risk_array[0]) for _ in range(nr_comparisons)
        ]
        var_matrix: List[List[SecureFixedPoint]] = [
            [secfxp(None)] * nr_comparisons for _ in range(nr_comparisons)
        ]

        for i in range(nr_comparisons):
            pre_vars[i] = self.mpc.schur_prod(var_factors, at_risk_array[i])
            neg_pre_vars[i] = [-x for x in pre_vars[i]]

        for i, (deaths, at_risk) in enumerate(zip(deaths_array, at_risk_array)):
            if i == nr_comparisons:
                break
            # Compute deviations from expected number of deaths
            devs[i] = self.mpc.sum(
                self.mpc.vector_sub(deaths, self.mpc.schur_prod(dev_factors, at_risk))
            )

            # Compute variances
            var_matrix[i][i] = self.mpc.sum(
                self.mpc.schur_prod(self.mpc.vector_sub(var_factors_2, pre_vars[i]), at_risk)
            )
            for j in (jj for jj in range(nr_comparisons) if jj != i):
                var_matrix[i][j] = self.mpc.sum(self.mpc.schur_prod(neg_pre_vars[j], at_risk))

        # Compute chi-value
        if nr_groups == 2:
            chi_sec = devs[0] ** 2 / var_matrix[0][0]
        else:
            await self.mpc.barrier()
            vars_inv = matrix_inverse(var_matrix)
            await self.mpc.barrier()
            chi_sec = self.mpc.in_prod(self.mpc.matrix_prod([devs], vars_inv)[0], devs)
        chi = await self.mpc.output(chi_sec)
        p = chi2.sf(chi, len(at_risk_array) - 1)
        return StatisticalResult(
            p_value=p,
            test_statistic=chi,
            test_name="secure_multivariate_logrank_test",
            null_distribution="chi squared",
            degrees_of_freedom=len(at_risk_array) - 1,
        )
    Player._secure_multivariate_logrank_test = _new_secure_multivariate_logrank_test

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
        self.mpc = setup(parties, index, ssl, output_file)
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
