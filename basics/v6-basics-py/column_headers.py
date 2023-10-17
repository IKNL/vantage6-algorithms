import pandas as pd

from vantage6.algorithm.tools.util import info
from vantage6.algorithm.tools.decorators import data


@data(1)
def column_headers(df: pd.DataFrame):
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
    return list(df.columns)
