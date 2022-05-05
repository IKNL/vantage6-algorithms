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
# Paths
path_data = pathlib.Path('../data')

# Make sure directories exist
if not path_data.exists():\
    path_data.mkdir(parents=True)


#%%
# Parameters for all cases
N_SAMPLES = 3000


#%%
# Dataset types
datasets = ['linear', 'logistic', 'poisson']

#%%
# Generate data for each type

for dataset in datasets:

    if dataset == 'linear':
        x1 = np.random.normal(1, 1, N_SAMPLES)
        x2 = np.random.normal(2, 1, N_SAMPLES)

        y = 0.25*x1 + 0.5*x2 + np.random.normal(0, 1, N_SAMPLES)

        # Create pandas DataFrame
        df = pd.DataFrame({'x1':x1, 'x2':x2, 'y':y})

    elif dataset == 'logistic':

        # Normally distributed data
        # Notice we are generating one redundant feature (x3).
        # In practice, we will not use it for the regressions.
        X, y_ = make_classification(n_samples=N_SAMPLES, n_features=3, n_informative=2, n_redundant=1, n_classes=2)

        # Get into the right shape
        # We need to go from a 1D to a 2D array (notice the transpose)
        y = np.array([y_]).T

        # Create pandas DataFrame
        df_ = np.concatenate((X, y), axis=1)
        df = pd.DataFrame(df_, columns=['x1', 'x2', 'x3', 'y'])


    elif dataset == 'poisson':
        x1 = np.random.normal(1, 1, N_SAMPLES)
        x2 = np.random.normal(2, 1, N_SAMPLES)

        y = np.round(np.exp(0.25*x1 + 0.5*x2 + np.random.normal(0, 1, N_SAMPLES))).astype(int)

        # Create pandas DataFrame
        df = pd.DataFrame({'x1':x1, 'x2':x2, 'y':y})

    # Randomly part into three "different" parties and save to CSV file
    parties = np.array_split(df, 3)

    for ii, df_current in enumerate(parties):
        df_current.to_csv(path_data/f'{dataset}_party{ii+1}.csv')

