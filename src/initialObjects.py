# This script contains the initialization objects for the trainer, as well as all constants used in the backend calculations.
import numpy as np

n_init = 21 #TODO: change back to default (21) after testing
n_update = 79 # TODO: change back to default (79) after testing
n_tot = n_init + n_update
n_opt = 5
plotting = False
simulations = []
Xtrain = np.expand_dims(np.linspace(0, 1, n_init), axis = 1)