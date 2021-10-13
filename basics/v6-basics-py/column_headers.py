import pandas

from vantage6.tools.util import info


def RPC_column_headers(data: pandas.DataFrame):
    """
    Reports the column headers

    Parameters
    ----------
    data : pandas.DataFrame
        data frame from the local data source (supplied by the node)

    Returns
    -------
    list
        list of strings containing the column headers
    """
    info("Reading Headers")
    return list(data.columns)
