import pandas

from vantage6.tools.util import info


def RPC_row_count(data: pandas.DataFrame):
    """
    Reports the number of rows in the local dataset

    Parameters
    ----------
    data : pandas.DataFrame
        data frame from the local data source (supplied by the node)

    Returns
    -------
    int
        number of rows in the dataset
    """
    info("Counting rows")
    return len(data.index)
