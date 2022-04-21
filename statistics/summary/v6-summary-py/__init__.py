import pandas
import time
import numpy

from vantage6.tools.util import warn, info


def master(client, data, columns, organizations_to_include='ALL'):
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
    info("Defining input parameters")
    input_ = {
        "method": "summary",
        "args": [],
        "kwargs": {
            "columns": columns
        }
    }

    # obtain organizations that are within my collaboration
    if organizations_to_include=='ALL':
        organizations = client.get_organizations_in_my_collaboration()
        ids = [organization.get("id") for organization in organizations]
    else:
        ids = organizations_to_include

    # collaboration and image are stored in the key, so we do not need
    # to specify these
    info("Creating node tasks")
    task = client.create_new_task(
        input_,
        organization_ids=ids
    )

    results = wait_and_collect(client, task)

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
    g_stats["column_names_correct"] = \
        all([x["column_names_correct"] for x in results])
    # info(f"correct={g_stats['column_names_correct']}")

    # count the total number of rows of all datasets
    info("Count the total number of all rows from all datasets")
    g_stats["number_of_rows"] = sum([x["number_of_rows"] for x in results])
    # info(f"n={g_stats['number_of_rows']}")

    # compute global statistics for numeric columns
    info("Computing numerical column statistics")
    numeric_columns = columns_series.loc[columns_series.isin(['numeric', 'n'])]
    for header in numeric_columns.keys():

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

        g_stats[header] = {
            "min": g_min,
            "max": g_max,
            "nan": g_nan,
            "mean": g_mean
        }

    # get variance and std, from global mean
    g_means = {header:g_stats.get(header, {}).get('mean') for header in numeric_columns.keys()}
    
    info("Calculating federated variance")
    input_ = {
        "method": "federated_variance_part",
        "args": [],
        "kwargs": {
            "g_means": g_means
        }
    }

    info("Creating node tasks")
    task = client.create_new_task(
        input_,
        organization_ids=ids
    )
    federated_variance_parts = wait_and_collect(client, task)

    for header in numeric_columns.keys():

        sum_n = sum([node_res[header]['len'] for node_res in federated_variance_parts])
        sum_fv_p2 = sum([node_res[header]['fv_part2'] for node_res in federated_variance_parts])
        
        var_federated = sum_fv_p2/sum_n
        std_federated = numpy.sqrt(var_federated) # Population Standard Deviation
        
        g_stats[header].update({'var': var_federated})
        g_stats[header].update({'std': std_federated})


    # compute global statistics for categorical columns
    info("Computing categorical column statistics")
    categorical_columns = \
        columns_series.loc[columns_series.isin(['category', 'c'])]
    for header in categorical_columns.keys():

        stats = [result["statistics"][header] for result in results]
        all_keys = list(set([key for result in results for key in
                             result["statistics"][header].keys()]))

        categories_dict = dict()
        for key in all_keys:
            key_sum = sum([x.get(key) for x in stats if key in x.keys()])
            categories_dict[key] = key_sum

        g_stats[header] = categories_dict

    g_stats = convert_np_to_py(g_stats)

    info("master algorithm complete")

    return g_stats


def RPC_summary(dataframe, columns):
    """
    Computes a summary of all columns of the dataframe

    Parameters
    ----------
    dataframe : pandas dataframe
        Pandas dataframe that contains the local data.
    columns : Dictionairy
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
    column_names_correct = set(list(columns_series.keys()))\
        .issubset(list(dataframe.keys()))
    if not column_names_correct:
        problematic_column_names = list(numpy.setdiff1d(
            list(columns_series.keys()),
            list(dataframe.keys()))
        )
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
    numeric_columns = columns_series.loc[columns_series.isin(['numeric', 'n'])]
    for column_name in numeric_columns.keys():
        info(f"Numerical column={column_name} is processed")
        column_values = dataframe[column_name]
        q1, median, q3 = column_values.quantile([0.25, 0.5, 0.75]).values
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
    categorical_columns = \
        columns_series.loc[columns_series.isin(['category', 'c'])]
    for column_name in categorical_columns.keys():
        info(f"Categorical column={column_name} is processed")
        columns[column_name] = dataframe[column_name].value_counts().to_dict()

    return {
        "column_names_correct": column_names_correct,
        "number_of_rows": number_of_rows,
        "statistics": columns
    }

def RPC_federated_variance_part(dataframe, g_means):
    """
    Federated variance can be calculated by:
    Var(X) = 1/(n_a + n_b) * sum_(j∈{a,b}) (sum_(i=1)^n_j (x_(j,i) - g_mean)^2)
    Where,
    Part 1: 1/(n_a + n_b)
    Part 2: sum_(j∈{a,b}) (sum_(i=1)^n_j (x_(j,i) - g_mean)^2)
        
    This function computes Part 2 of the variance needed for calculating the 
    federated variance, for a single party, let's say party b in this case.
    
    Parameters
    ----------
    dataframe : pandas dataframe
        Pandas dataframe that contains the local data.
    g_means : Dictionairy
        Dictionary of the (numeric) headers (column names) of the dataframe and their corresponding global means.

    Returns
    -------
    Dict
        A Dict containing, pet key in g_means: 
            number of values (n_b) - part of part 1
            sum_(i=1)^n_j (x_(j,i) - g_mean)^2 for party b - part of part 2
    """

    federated_variance_parts = dict()
    
    for header, g_mean in g_means.items():
        
        data = dataframe[header]
        data.dropna(inplace=True)
        n = len(data)
        fv_p2 = sum((data-g_mean)**2)
        
        federated_variance_parts[header] = {'len': n, 'fv_part2': fv_p2}

    return federated_variance_parts


def convert_np_to_py(d):
    """
    Converts numpy instances in a dictionary to native python instances.
    Background information : the wrapper could not serialize numpy instances to JSON. 
    
    Parameters
    ----------
    d : Dictionairy

    Returns
    -------
    Dict
        A Dict without numpy instances.
    """
    for k, v in d.items():
        if isinstance(v, dict):
            convert_np_to_py(v)
        else:
            if 'numpy' in type(v).__module__:
                d[k] = v.item()
    return(d)


def wait_and_collect(client, task):
    """
    Waits till the nodes are done with processing a task, and 
    collects the results.
    
    Parameters
    ----------
    client : ContainerClient
        Interface to the central server. This is supplied by the wrapper.
    task : Dictionary
        vantage6 task information obtained from client.create_new_task().

    Returns
    -------
    Dict
        A Dict with result dictionaries per node.
    """
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

    return results
