# This script contains the initialization objects for the trainer, as well as all constants used in the backend calculations.
import numpy as np

n_init = 10 #TODO: change back to default of 21 after testing
n_update = 15 - n_init # TODO: change back to default (100) after testing
n_opt = 5
plotting = False
simulations = []
Xtrain = np.expand_dims(np.linspace(0, 1, n_init), axis = 1)
