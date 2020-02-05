from matplotlib import pyplot as plt
import numpy as np
import GPy
from GPy.likelihoods.link_functions import GPTransformation
from GPy.util.univariate_Gaussian import std_norm_cdf, std_norm_pdf
from GPy.util.misc import safe_exp, safe_square, safe_cube, safe_quad, safe_three_times

def g_log(X):
    return 1./(1+np.exp(-X))

class Logit(GPTransformation):
    """
    .. math::

        g(f) = \\1/(1+exp(-f)

    """
    def transf(self,f):
        return g_log(f)


    def dtransf_df(self,f):
        return g_log(f)*(1-g_log(f))


    def d2transf_df2(self,f):
        return g_log(f)*(g_log(-f))*(g_log(-f)-g_log(f))


    def d3transf_df3(self,f):
        return g_log(f)*(g_log(-f))*(g_log(-f)-g_log(f))*(1-2*g_log(f))-2*(g_log(f)*(1-g_log(f)))**2

    def to_dict(self):
        """
        Convert the object into a json serializable dictionary.

        Note: It uses the private method _save_to_input_dict of the parent.

        :return dict: json serializable dictionary containing the needed information to instantiate the object
        """

        input_dict = super(Logit, self)._save_to_input_dict()
        input_dict["class"] = "GPy.likelihoods.link_functions.Logit"
        return input_dict

def bo_acquisition(m, X):
    pred_f = m.predict_noiseless(X)
    acquisition_f = pred_f[0] + 2. * np.sqrt(pred_f[1])
    return(acquisition_f)

def gen_sim(Xi):
    """
    Generates random draws from a Binomial distribution

    X: vector of probabilities to serve as the second parameter in the Binomial draw

    Yes, this is just a wrapper for numpy.random.binomial() and could be replaced with rbinom() in R. Just bear with me for now, will ya? The idea for now is to have R only working in the frontend (and the Shiny server side).
    """
    ss = np.random.binomial(n = 100, p = Xi)
    return(ss)

def plotting(Xtrain, ytrain, pred_f, Xgrid, lik_proxy, post_proxy, m, stage = 1):
    if (stage == 1):
        plt.scatter(Xtrain, ytrain)
        plt.show()

        plt.plot(Xgrid, pred_f[0])
        plt.plot(Xgrid, pred_f[0] + 1.96 * np.sqrt(pred_f[1]))
        plt.plot(Xgrid, pred_f[0] - 1.96 * np.sqrt(pred_f[1]))
        plt.show()

        plt.plot(Xgrid, bo_acquisition(m, Xgrid))
        plt.show()
    else:
        plt.plot(Xgrid, pred_f[0])
        plt.plot(Xgrid, pred_f[0] + 1.96 * np.sqrt(pred_f[1]))
        plt.plot(Xgrid, pred_f[0] - 1.96 * np.sqrt(pred_f[1]))
        plt.show()

        plt.plot(Xgrid, bo_acquisition(m, Xgrid))
        plt.show()

        plt.plot(Xgrid, lik_proxy)
        plt.show()

        plt.plot(Xgrid, post_proxy)
        plt.show()

        plt.scatter(m.X, m.Y)
        plt.show()

def model_fit(Xtrain, ytrain):
    # Kernel
    kern = GPy.kern.Matern32(input_dim = 1) \
    + GPy.kern.White(input_dim = 1) \
    + GPy.kern.Bias(input_dim = 1)
    kern.Mat32.variance.set_prior(GPy.priors.Gamma.from_EV(1., 1.))

    # Likelihood
    logit_link = Logit()
    lik_link = GPy.likelihoods.Bernoulli(gp_link = logit_link)

    # inference method
    laplace_inf = GPy.inference.latent_function_inference.Laplace()

    # Model fit
    m = GPy.models.GPClassification(
        Xtrain, ytrain, kernel = kern, likelihood = lik_link,
        inference_method = laplace_inf
    )

    m.optimize() #first runs EP and then optimizes the kernel parameters
    return(m)

def model_update(m, X_acq, y_acq, i, n_opt):
    # Kernel
    thiskern = m.kern.copy()

    # Likelihood
    logit_link = Logit()
    lik_link = GPy.likelihoods.Bernoulli(gp_link = logit_link)

    # Inference method
    laplace_inf = GPy.inference.latent_function_inference.Laplace()
    
    # X and Y
    x = np.r_[m.X, X_acq]
    y = np.r_[m.Y, y_acq]

    # Model fit
    m = GPy.models.GPClassification(
        x, y, kernel = thiskern, likelihood = lik_link,
        inference_method = laplace_inf
    ) 

    if (i % n_opt) == 0:
        m.optimize()
    
    return(m)

def acquire_X(m, acq_noise = 0.1):
    Xgrid = np.expand_dims(np.linspace(0, 1, 2001), axis = 1)

    # for i in range(n_update):
    thisXgrid = Xgrid.copy()
    X_acq = np.expand_dims(
        thisXgrid[np.argmax(bo_acquisition(m, thisXgrid)), :], axis = 1
    )
    X_acq += np.random.normal(0, acq_noise, np.shape(X_acq))
    X_acq = min(max(X_acq, 0 * X_acq), X_acq / X_acq)
    return(X_acq)

def calc_post_proxy(m, Xgrid):
    lik_proxy = np.exp(m.predict_noiseless(Xgrid)[0])

    post_proxy = lik_proxy / (np.sum(lik_proxy*0.01))
    return(post_proxy)
