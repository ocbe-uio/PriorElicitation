# This script contains functions serving GP-Classifier-BayesOpt-Binomial.py
import numpy as np

def bo_acquisition(m, X):
    pred_f = m.predict_noiseless(X)
    acquisition_f = pred_f[0] + 2. * np.sqrt(pred_f[1])
    return(acquisition_f)

def y_sample(X):
    # TODO: split this function into others below
    judgement=np.zeros((np.shape(X)[0],1))
    for i in range(np.shape(X)[0]):
        ss=np.random.binomial(n=100,p=X[i])
        # simulations.append(ss)
        #THIS IS THE MAGIC INTERSECTION POINT - GIVE THE WRAPPER A SIMULATION, GET A BINARY LABEL BACK
        judgement[i]=1.*(ss>35)*(ss<65)
    return(judgement)

def gen_sim(Xi):
    """
    Generates random draws from a Binomial distribution

    X: vector of probabilities to serve as the second parameter in the Binomial draw

    Yes, this is just a wrapper for numpy.random.binomial() and could be replaced with rbinom() in R. Just bear with me for now, will ya? The idea for now is to have R only working in the frontend (and the Shiny server side).
    """
    ss = np.random.binomial(n = 100, p = Xi)
    return(ss)
