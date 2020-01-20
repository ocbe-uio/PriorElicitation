# This script uses the reticulate package to call the Python scripts in R

library(reticulate)

source_python("GPy_logit_link.py")
source_python("GP-Classifier-BayesOpt-Binomial.py")