# -*- coding: utf-8 -*-
"""
In this script, we will generate the data for the
validation of the federated GLM algorithm

Created on Fri Apr 22 15:42:47 2022
"""

#%%
import pathlib
import pandas as pd
import numpy as np
from sklearn.datasets import make_classification

#%%
def create_dataset(data_type='linear', n_samples=3000, n_parties=3, path_data=None):
    """
    Generate a dataset of certain type for the valiation of the
    federated GLM algorithm.

    Parameters
    ----------
    data_type_: string
        Type of desired data. Possible values are:
            'linear' (default)
            'logistic'
            'poisson'
    n_samples: numeric
        Desired number of TOTAL records.
        Default value is 3000
    n_parties: numeric
        Desired number of parties. Each party will have (almost) the same
        number of records randomly assigned.
        Default value is 3.
    path_data: string
        If different than None (which is the default), the data will
        be saved as .csv files in the provided path.

    Returns
    -------
    parties: list
        A list with each element being a pandas DataFrame corresponding
        to the data of that party.
    """

    print(data_type)

    if data_type == 'linear':
        x1 = np.random.normal(1, 1, n_samples)
        x2 = np.random.normal(2, 1, n_samples)

        y = 0.25*x1 + 0.5*x2 + np.random.normal(0, 1, n_samples)

        # Create pandas DataFrame
        df = pd.DataFrame({'x1':x1, 'x2':x2, 'y':y})

    elif data_type == 'logistic':

        # Normally distributed data
        # Notice we are generating one redundant feature (x3).
        # In practice, we will not use it for the regressions.
        X, y_ = make_classification(n_samples=n_samples, n_features=3, n_informative=2, n_redundant=1, n_classes=2)

        # Get into the right shape
        # We need to go from a 1D to a 2D array (notice the transpose)
        y = np.array([y_]).T

        # Create pandas DataFrame
        df_ = np.concatenate((X, y), axis=1)
        df = pd.DataFrame(df_, columns=['x1', 'x2', 'x3', 'y'])
        pass

    elif data_type == 'poisson':
        x1 = np.random.normal(1, 1, n_samples)
        x2 = np.random.normal(2, 1, n_samples)

        y = np.round(np.exp(0.25*x1 + 0.5*x2 + np.random.normal(0, 1, n_samples))).astype(int)

        # Create pandas DataFrame
        df = pd.DataFrame({'x1':x1, 'x2':x2, 'y':y})

    # Randomly part into three "different" parties and save to CSV file
    parties = np.array_split(df, 3)


    if path_data != None:
        for ii, df_current in enumerate(parties):
            df_current.to_csv(path_data/f'{data_type}_party{ii+1}.csv')

    return parties


#%%
if __name__ == '__main__':

    # Parameters
    N_SAMPLES = 3000
    N_PARTIES = 3

    # Paths
    path_data = pathlib.Path('../data')

    # Make sure directories exist
    if not path_data.exists():
        path_data.mkdir(parents=True)


    # Dataset types
    data_types = ['linear', 'logistic', 'poisson']
    # data_types = ['linear', 'poisson']

    for data_type in data_types:
        create_dataset(data_type, N_SAMPLES, N_PARTIES, path_data)