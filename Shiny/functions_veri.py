import numpy as np
import GPy
from GPy.likelihoods.link_functions import GPTransformation
# from GPy.util.univariate_Gaussian import std_norm_cdf, std_norm_pdf
# from GPy.util.misc import safe_exp, safe_square, safe_cube, safe_quad,
# safe_three_times


def g_log(X):
    return 1./(1+np.exp(-X))


class Logit(GPTransformation):
    """
    .. math::

        g(f) = \\1/(1+exp(-f)

    """
    def transf(self, f):
        return g_log(f)

    def dtransf_df(self, f):
        return g_log(f)*(1-g_log(f))

    def d2transf_df2(self, f):
        return g_log(f)*(g_log(-f))*(g_log(-f)-g_log(f))

    def d3transf_df3(self, f):
        return g_log(f)*(g_log(-f))*(g_log(-f)-g_log(f))*(1-2*g_log(f)) \
            - 2 * (g_log(f)*(1-g_log(f)))**2

    def to_dict(self):
        """
        Convert the object into a json serializable dictionary.

        Note: It uses the private method _save_to_input_dict of the parent.

        :return dict: json serializable dictionary containing the needed
            information to instantiate the object
        """

        input_dict = super(Logit, self)._save_to_input_dict()
        input_dict["class"] = "GPy.likelihoods.link_functions.Logit"
        return input_dict


def bo_acquisition(m, X):
    pred_f = m.predict_noiseless(X)
    acquisition_f = pred_f[0] + 2. * np.sqrt(pred_f[1])
    return(acquisition_f)


def gen_sim(Xi, fix_seed=False):
    """
    Generates random draws from a Binomial distribution

    X: vector of probabilities to serve as the second parameter in the Binomial
        draw

    Yes, this is just a wrapper for numpy.random.binomial() and could be
        replaced with rbinom() in R. Just bear with me for now, will ya?
        The idea for now is to have R only working in the frontend
        (and the Shiny server side).
    """
    if (fix_seed):
        np.random.seed(848855)
    ss = np.random.binomial(n=100, p=Xi)
    return(ss)


def model_fit_veri(Xtrain, ytrain):
    # Kernel
    kern = GPy.kern.Matern32(input_dim=1) \
        + GPy.kern.White(input_dim=1) \
        + GPy.kern.Bias(input_dim=1)
    kern.Mat32.variance.set_prior(GPy.priors.Gamma.from_EV(1., 1.))

    # Likelihood and inference method (identical to model_update)
    logit_link = Logit()
    lik_link = GPy.likelihoods.Bernoulli(gp_link=logit_link)
    laplace_inf = GPy.inference.latent_function_inference.Laplace()

    # Model fit
    m = GPy.models.GPClassification(
        Xtrain, ytrain, kernel=kern, likelihood=lik_link,
        inference_method=laplace_inf
    )

    m.optimize()  # first runs EP and then optimizes the kernel parameters
    return(m)


def model_update_veri(m, X_acq, y_acq, i, n_opt):
    # import pdb; pdb.set_trace() # debugging breakpoint
    # Kernel
    thiskern = m.kern.copy()

    # Likelihood and inference method (identical to model_fit)
    logit_link = Logit()
    lik_link = GPy.likelihoods.Bernoulli(gp_link=logit_link)
    laplace_inf = GPy.inference.latent_function_inference.Laplace()

    # Creating X and Y with the historical values (m.*) + the latest (acq)
    x = np.r_[m.X, X_acq]
    y = np.r_[m.Y, y_acq]

    # Model fit
    m = GPy.models.GPClassification(
        x, y, kernel=thiskern, likelihood=lik_link,
        inference_method=laplace_inf
    )

    if (i % n_opt) == 0:
        m.optimize()

    return(m)


def acquire_X_veri(m, Xgrid, acq_noise=0.1, fix_seed=False):
    # for i in range(n_update):
    thisXgrid = Xgrid.copy()
    X_acq = np.expand_dims(
        thisXgrid[np.argmax(bo_acquisition(m, thisXgrid)), :], axis=1
    )
    if (fix_seed):
        np.random.seed(848855)
    X_acq += np.random.normal(0, acq_noise, np.shape(X_acq))
    X_acq = min(max(X_acq, 0 * X_acq), X_acq / X_acq)
    return(X_acq)


def calc_lik_proxy_veri(m, Xgrid):
    lik_proxy = np.exp(m.predict_noiseless(Xgrid)[0])
    return(lik_proxy)


def calc_post_proxy(lik_proxy):
    post_proxy = lik_proxy / (np.sum(lik_proxy * 0.01))
    return(post_proxy)


def calc_pred_f(m, Xgrid):
    pred_f = m.predict_noiseless(Xgrid)
    return(pred_f)
