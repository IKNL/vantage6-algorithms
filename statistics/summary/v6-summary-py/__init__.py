import sys
import pandas
import time
import numpy
import json

from vantage6.tools.util import warn, info


def master(client, data, columns):
    """
    Master algorithm to compute a summary of the federated datasets.

    Parameters
    ----------
    client : ContainerClient
        Interface to the central server. This is supplied by the wrapper.
    data : dataframe
        Pandas dataframe. This is supplied by the wrapper / node.
    columns : Dictonairy
        Dict containing column names and types

    Returns
    -------
    Dict
        A dictonairy containing summary statistics for all the columns of the
        dataset.
    """
    # define the input for the summary algorithm
    info("Defining input paramaeters")
    input_ = {
        "method": "summary",
        "args": [],
        "kwargs": {
            "columns": columns
        }
    }

    # obtain organizations that are within my collaboration
    organizations = client.get_organizations_in_my_collaboration()
    ids = [organization.get("id") for organization in organizations]

    # collaboration and image is stored in the key, so we do not need
    # to specify these
    info("Creating node tasks")
    task = client.create_new_task(
        input_,
        organization_ids=ids
    )

    # wait for all results
    # TODO subscribe to websocket, to avoid polling
    task_id = task.get("id")
    task = client.request(f"task/{task_id}")
    while not task.get("complete"):
        task = client.request(f"task/{task_id}")
        info("Waiting for results")
        time.sleep(1)

    info("Obtaining results")
    results = client.get_results(task_id=task.get("id"))

    info("Check that column names are correct")
    if not all(x['column_names_correct'] for x in results):
        warn("Column names are not correct on all sites?!")
        return None

    # process the output
    info("Process node info to global stats")
    columns_series = pandas.Series(columns)
    g_stats = {}

    # check that all dataset reported their headers are correct
    info("Check if all column names on all sites are correct")
    g_stats["column_names_correct"] = all([x["column_names_correct"] for x in results])
    # info(f"correct={g_stats['column_names_correct']}")

    # count the total number of rows of all datasets
    info("Count the total number of all rows from all datasets")
    g_stats["number_of_rows"] = sum([x["number_of_rows"] for x in results])
    # info(f"n={g_stats['number_of_rows']}")

    # compute global statistics for numeric columns
    info("Computing numerical column statistics")
    numeric_colums = columns_series.loc[columns_series.isin(['numeric','n'])]
    for header in numeric_colums.keys():

        n = g_stats["number_of_rows"]

        # extract the statistics for each column and all results
        stats = [result["statistics"][header] for result in results]

        # compute globals
        g_min = min([x.get("min") for x in stats])
        # info(f"g_min={g_min}")
        g_max = max([x.get("max") for x in stats])
        # info(f"g_max={g_max}")
        g_nan = sum([x.get("nan") for x in stats])
        # info(f"g_nan={g_nan}")
        g_mean = sum([x.get("sum") for x in stats]) / (n-g_nan)
        # info(f"g_mean={g_mean}")
        g_std = (sum([x.get("sq_dev_sum") for x in stats]) / (n-1-g_nan))**(0.5)

        # estimate the median
        # see https://stats.stackexchange.com/questions/103919/estimate-median-from-mean-std-dev-and-or-range
        u_std = (((n-1)/n)**(0.5)) * g_std
        g_median = [
            max([g_min, g_mean - u_std]),
            min([g_max, g_mean + u_std])
        ]

        g_stats[header] = {
            "min": g_min,
            "max": g_max,
            "nan": g_nan,
            "mean": g_mean,
            "std": g_std,
            "median": g_median
        }

    # compute global statistics for categorical columns
    info("Computing categorical column statistics")
    categorical_columns = columns_series.loc[columns_series.isin(['category', 'c'])]
    for header in categorical_columns.keys():
        
        stats = [result["statistics"][header] for result in results]
        all_keys = list(set([key for result in results for key in result["statistics"][header].keys()]))
        
        categories_dict = dict()
        for key in all_keys:
            key_sum = sum([x.get(key) for x in stats if key in x.keys()])
            categories_dict[key] = key_sum

        g_stats[header] = categories_dict

    info("master algorithm complete")

    return g_stats

def RPC_summary(dataframe, columns):
    """
    Computes a summary of all columns of the dataframe

    Parameters
    ----------
    dataframe : pandas dataframe
        Pandas dataframe that contains the local data.
    columns : Dictonairy
        Dict containing column name and column (panda) type pairs

    Returns
    -------
    Dict
        A Dict containing some simple statistics for the local dataset.
    """

    # create series from input column names
    columns_series = pandas.Series(data=columns)

    # compare column names from dataset to the input column names
    info("Checking (given) column-names")
    column_names_correct = set(list(columns_series.keys())).issubset(list(dataframe.keys()))
    if not column_names_correct:
        problematic_column_names = list(numpy.setdiff1d(list(columns_series.keys()), list(dataframe.keys())))
        warn("Column names do not match. Exiting.")
        return {"column_names_correct": column_names_correct, 
                "column_names_not_in_dataset": problematic_column_names}
    
    dataframe = dataframe[list(columns.keys())]

    # count the number of rows in the dataset
    info("Counting number of rows")
    number_of_rows = len(dataframe)
    if number_of_rows < 10:
        warn("Dataset has less than 10 rows. Exiting.")
        return {
            "column_names_correct": column_names_correct,
            "number_of_rows": number_of_rows
        }

    # min, max, median, average, Q1, Q3, missing_values
    columns = {}
    numeric_colums = columns_series.loc[columns_series.isin(['numeric','n'])]
    for column_name in numeric_colums.keys():
        info(f"Numerical column={column_name} is processed")
        column_values = dataframe[column_name]
        q1, median, q3 = column_values.quantile([0.25,0.5,0.75]).values
        mean = column_values.mean()
        minimum = column_values.min()
        maximum = column_values.max()
        nan = column_values.isna().sum()
        total = column_values.sum()
        std = column_values.std()
        sq_dev_sum = (column_values-mean).pow(2).sum()
        columns[column_name] = {
            "min": minimum,
            "q1": q1,
            "median": median,
            "mean": mean,
            "q3": q3,
            "max": maximum,
            "nan": int(nan),
            "sum": total,
            "sq_dev_sum": sq_dev_sum,
            "std": std
        }

    # return the categories in categorial columns
    categorical_columns = columns_series.loc[columns_series.isin(['category', 'c'])]
    for column_name in categorical_columns.keys():
        info(f"Categorical column={column_name} is processed")
        columns[column_name] = dataframe[column_name].value_counts().to_dict()

    return {
        "column_names_correct": column_names_correct,
        "number_of_rows": number_of_rows,
        "statistics": columns
    }