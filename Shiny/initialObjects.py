# This script contains the initialization objects for the trainer, as well as
# all constants used in the backend calculations.
import numpy as np

# ==============================================================================
# Manual debugging switch
# ==============================================================================
debug = False

n_opt = 5
plotting = False
simulations = []


def init_n(debug, precious_type):
    # Debug or not?
    if debug:
        n_init = 4
        n_update = 6
    else:
        if precious_type == "veri":
            n_init = 21
            n_update = 79
        else:
            n_init = 6
            n_update = 12
    # Fixing grid size for pari
    if precious_type == "pari":
        # See issue #1 for details
        # https://github.com/ocbe-uio/PriorElicitation/issues/1#issuecomment-664196098
        n_init = n_init * (n_init + 1) / 2
        n_update = n_update * (n_update + 1) / 2
    n_tot = n_init + n_update
    return(n_init, n_tot)


def init_X(precious_type, n_init):
    if precious_type == "veri":
        Xtrain = np.expand_dims(np.linspace(0, 1, n_init), axis=1)
        Xgrid = np.expand_dims(np.linspace(0, 1, 2001), axis=1)
        return(Xtrain, Xgrid)
    elif precious_type == "pari":
        # For Pari-PRECIOUS
        init_grid_indices = np.triu_indices(n_init)
        anti_init_grid_indices = np.tril_indices(n_init)
        Xtrain = np.random.uniform(0, 1, (n_init, 1))
        X1train = np.linspace(0, 1, n_init)
        X2train = np.linspace(0, 1, n_init)
        X1traingrid, X2traingrid = np.meshgrid(X1train, X2train)
        Xtrain = np.concatenate(
            (
                np.reshape(X1traingrid[init_grid_indices], (-1, 1)),
                np.reshape(X2traingrid[init_grid_indices], (-1, 1))
            ),
            axis=1
        )
        return(
            init_grid_indices, anti_init_grid_indices, Xtrain, X1train,
            X2train, X1traingrid, X2traingrid, Xtrain
        )
    else:
        raise ValueError("Invalid type")
