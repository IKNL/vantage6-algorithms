import pandas as pd

from vantage6.algorithm.tools.util import info
from vantage6.algorithm.tools.decorators import data


@data(1)
def row_count(df: pd.DataFrame):
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
    return len(df.index)
