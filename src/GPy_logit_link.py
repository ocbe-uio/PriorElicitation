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