from matplotlib import pyplot as plt
# get_ipython().run_line_magic('matplotlib', 'inline') # TODO: part of plotting. Remove?
import sys
import csv
import numpy as np
import GPy
from IPython.display import clear_output
from scipy.stats import norm
# from GPy_logit_link import Logit, g_log


# In[38]:


def sample_crp(alpha, theta, n):
    membership = [1]
    for i in range(1, n):
        probs = [(m-alpha)/(i+theta) for m in membership]+[(theta+len(membership)*alpha)/(i+theta)]
        newmember = np.random.multinomial(n=1, pvals=np.array(probs)).tolist()
        if newmember[-1]:
            membership = membership+[1]
        else:
            membership = [membership[m]+newmember[m] for m in range(len(membership))]
    membership.sort(reverse=True)
    return(membership)

# In[41]:


def y_input(X):
    # judgement = np.zeros((np.shape(X)[0], 1))
    for i in range(np.shape(X)[0]):  # i goes from 0 to nrow(X)
        members_0 = sample_crp(X[i, 0], 0., 100)
        members_1 = sample_crp(X[i, 1], 0., 100)
        # Random procedure below rendomizes order of plots
        # bin_rand = np.random.binomial(n = 1, p = .5)
        # if bin_rand: # == 1
        #     # TODO: move plotting to R
        #     plt.subplot(1, 2, 1)
        #     plt.bar(height = members_1, x = range(len(members_1)))
        #     plt.subplot(1, 2, 2)
        #     plt.bar(height = members_0, x = range(len(members_0)))
        #     plt.show()
        # else: # == 0
        #     # TODO: move plotting to R
        #     plt.subplot(1, 2, 1)
        #     plt.bar(height = members_0, x = range(len(members_0)))
        #     plt.subplot(1, 2, 2)
        #     plt.bar(height = members_1, x = range(len(members_1)))
        #     plt.show()
        # judgement[i] = float(float(input()) = =bin_rand) # FIXME: input() should ask for text input
        # # TODO: input() should come from Shiny
    # return(judgement)

def gen_X_plots_values(X):
    members_0 = sample_crp(X[0], 0., 100)
    members_1 = sample_crp(X[1], 0., 100)
    return(members_0, members_1)

# In[43]:


def labels_acquisition(m, X):
    lik_proxy = m.predict(X)[0]
    acquisition_label = -np.square(lik_proxy-0.5)
    return(acquisition_label)


# In[44]:


def var_acquisition(m, X):
    acquisition_f = np.sqrt(pred_f[1])
    return(acquisition_f)


# In[45]:


def hPHI(x):
    return (-norm.cdf(x)*norm.logcdf(x)-(1-norm.cdf(x))*norm.logcdf(-x))



# In[46]:


def bald_acquisition(m, X):
    pred_mean, pred_var = m.predict_noiseless(X)
    C = np.sqrt((np.pi*np.log(2))/2)
    term1 = hPHI(pred_mean/np.sqrt(pred_var+1))
    term2 = (
        -C * np.exp(-.5 * np.square(pred_mean) / (pred_var + C ** 2))
        / np.sqrt(pred_var + C ** 2)
    )
    return(term1+term2)


# In[47]:


def dts_acquisition_X(m, X):
    pred_noiseless_mean, pred_noiseless_var = m.predict_noiseless(X, full_cov = False)
    #pred_noiseless_samples = np.random.multivariate_normal(mean = pred_noiseless_mean[:, 0], cov = pred_noiseless_var, size = 1000)
    pred_noiseless_samples = np.random.normal(size = (2601, 1000)) * np.sqrt(pred_noiseless_var) + pred_noiseless_mean
    pred_labels_samples= np.mean(g_log(pred_noiseless_samples), axis = 1)
    n_this = int(np.sqrt(np.shape(X)[0]))
    pred_label = np.reshape(pred_labels_samples, (n_this, n_this))
    copeland = np.argmax(np.sum(pred_label, axis = 0))
    acq_0 = copeland
 #   plt.plot(np.sum(pred_label, axis = 0))
    thisX1grid = np.reshape(X[:, 1], (n_this, n_this))
    thisX0grid = np.reshape(X[:, 0], (n_this, n_this))
    X_DTS_grid = np.concatenate((thisX0grid[copeland:copeland+1, :].T, thisX1grid[copeland, 0]*np.ones((n_this, 1))), axis = 1)
    pred_DTS_mean, pred_DTS_var = m.predict_noiseless(X_DTS_grid, full_cov = True)
    DTS_samples = np.random.multivariate_normal(mean = pred_DTS_mean[:, 0], cov = pred_DTS_var, size = 500)
    DTS_samples_var = np.var(DTS_samples, axis = 0)
    #plt.plot(DTS_samples_var)
    acq_1 = np.argmax(DTS_samples_var)
    X_acq = np.concatenate((thisX0grid[acq_0:acq_0+1, acq_1:acq_1+1], thisX1grid[acq_0:acq_0+1, acq_1:acq_1+1]), axis = 1)
  #  print("X_acq", X_acq)
   # plt.show()
   # input()
    return(X_acq)


# TODO: No more functions. The rest is the script to be ported to R

# # In[50]:

# ytrain = y_input(Xtrain)


# In[51]:


# Xtrainmirror = np.concatenate((np.reshape(X2traingrid[init_grid_indices], (-1, 1)), np.reshape(X1traingrid[init_grid_indices], (-1, 1))), axis = 1)
# ytrainmirror = 1-ytrain

# Xtrainfull = np.concatenate((Xtrain, Xtrainmirror), axis = 0)
# ytrainfull = np.concatenate((ytrain, ytrainmirror), axis = 0)


# # In[52]:


# kern = GPy.kern.Matern32(input_dim = 1, active_dims = 0)+GPy.kern.Matern32(input_dim = 1, active_dims = 1)#+GPy.kern.White(input_dim = 1)+GPy.kern.Bias(input_dim = 1)#+GPy.kern.Poly(input_dim = 1, order = 2.0)
# kern.Mat32.variance.set_prior(GPy.priors.Gamma.from_EV(1., 1.))
# kern.Mat32_1.variance.set_prior(GPy.priors.Gamma.from_EV(1., 1.))

# #kern = GPy.kern.Matern32(input_dim = 1)+GPy.kern.Bias(input_dim = 1)

# logit_link = Logit()

# lik_link = GPy.likelihoods.Bernoulli(gp_link = logit_link)

# laplace_inf = GPy.inference.latent_function_inference.Laplace()

# m = GPy.models.GPClassification(Xtrainfull, ytrainfull, kernel = kern, likelihood = lik_link, inference_method = laplace_inf)

# m.optimize() #first runs EP and then optimizes the kernel parameters


# # In[53]:


# n_test = 51

# test_grid_indices = np.triu_indices(n_test)

# X1test = np.expand_dims(np.linspace(0, 1,n_test), axis = 1)
# X2test = np.expand_dims(np.linspace(0, 1,n_test), axis = 1)

# X1testgrid, X2testgrid = np.meshgrid(X1test, X2test)
# Xtest = np.concatenate((np.reshape(X1testgrid, (-1, 1)), np.reshape(X2testgrid, (-1, 1))), axis = 1)

# Xacq = np.concatenate((np.reshape(X1testgrid[test_grid_indices], (-1, 1)), np.reshape(X2testgrid[test_grid_indices], (-1, 1))), axis = 1)


# # In[54]:


# lik_proxy = np.exp(m.predict_noiseless(Xtest)[0])
# loglik_proxy = m.predict_noiseless(Xtest)[0]
# loglik_proxy = np.reshape(loglik_proxy, (n_test, n_test))
# lik_proxy = np.reshape(lik_proxy, (n_test, n_test))


# # In[55]:


# plt.contour(X1testgrid, X2testgrid, lik_proxy)


# # In[56]:


# plt.contour(X1testgrid, X2testgrid, np.log(lik_proxy))


# # In[57]:


# arg_real = np.nonzero(ytrain[:, 0])
# arg_fake = np.nonzero(1-ytrain[:, 0])

# plt.scatter(np.reshape(X1traingrid[init_grid_indices], (-1, 1))[arg_real, 0], np.reshape(X2traingrid[init_grid_indices], (-1, 1))[arg_real, 0], c = 'r')
# plt.scatter(np.reshape(X1traingrid[init_grid_indices], (-1, 1))[arg_fake, 0], np.reshape(X2traingrid[init_grid_indices], (-1, 1))[arg_fake, 0], c = 'b')
# plt.scatter(np.reshape(X2traingrid[init_grid_indices], (-1, 1))[arg_fake, 0], np.reshape(X1traingrid[init_grid_indices], (-1, 1))[arg_fake, 0], c = 'r')
# plt.scatter(np.reshape(X2traingrid[init_grid_indices], (-1, 1))[arg_real, 0], np.reshape(X1traingrid[init_grid_indices], (-1, 1))[arg_real, 0], c = 'b')


# # In[58]:


# plt.contour(X1testgrid, X2testgrid, np.reshape(bald_acquisition(m, Xtest), (n_test, n_test)))


# # In[59]:


# a, b = np.unravel_index(np.argmax(lik_proxy), (n_test, n_test))
# plt.plot(X1test, lik_proxy[b, :])
# plt.show()


# # In[60]:


# n_update = 50-int(.5*n_init**2)-3
# acq_noise = 0.1


# # In[61]:


# n_opt = 5


# # In[62]:


# for i in range(n_update):
#     thisXacq = Xtest.copy()
#     X_acq_opt = dts_acquisition_X(m, thisXacq)
#     X_acq_opt+ = np.random.normal(0, acq_noise, np.shape(X_acq_opt))
#     X_acq_opt[:, 0] = np.clip(X_acq_opt[:, 0], 0,1)
#     X_acq_opt[:, 1] = np.clip(X_acq_opt[:, 1], 0,1)

#     y_acq = y_input(X_acq_opt)
#     #print("X y", X_acq, y_acq, i)

#     x = np.r_[m.X, X_acq_opt]
#     y = np.r_[m.Y, y_acq]

#     x = np.r_[x, np.flip(X_acq_opt, axis = 1)]
#     y = np.r_[y, 1-y_acq]





#     thiskern = m.kern.copy()
#     # It seems that GPy will do some optimization unless you make copies of everything
#     m = GPy.models.GPClassification(x, y,kernel = kern, likelihood = lik_link, inference_method = laplace_inf)
#     if (i%n_opt) = =0:
#         m.optimize()
#        # print(m.kern)


# # In[63]:


# lik_proxy = np.exp(m.predict_noiseless(Xtest)[0])
# loglik_proxy = m.predict_noiseless(Xtest)[0]
# loglik_proxy = np.reshape(loglik_proxy, (n_test, n_test))
# lik_proxy = np.reshape(lik_proxy, (n_test, n_test))


# # In[64]:


# m


# # In[65]:


# m.optimize()


# # In[66]:


# plt.contour(X1testgrid, X2testgrid, lik_proxy)


# # In[67]:


# plt.contour(X1testgrid, X2testgrid, np.log(lik_proxy))


# # In[68]:


# arg_real = np.nonzero(m.Y)
# arg_fake = np.nonzero(1-m.Y)


# plt.scatter(m.X[arg_real, 0], m.X[arg_real, 1], c = 'b')
# plt.scatter(m.X[arg_fake, 0], m.X[arg_fake, 1], c = 'r')


# # In[69]:


# a, b = np.unravel_index(np.argmax(lik_proxy), (n_test, n_test))
# plt.plot(X1test, lik_proxy[b, :])
# plt.show()


# # In[70]:


# #ADD PERSON'S NAME!!!!
# person = 'mari'
# country = 'usa'


# # In[71]:


# path = './preferenceresults/'+person+'_'+country+'u'


# # In[72]:


# lik_proxy = np.exp(m.predict_noiseless(Xtest)[0])
# loglik_proxy = m.predict_noiseless(Xtest)[0]
# loglik_proxy = np.reshape(loglik_proxy, (n_test, n_test))
# lik_proxy = np.reshape(lik_proxy, (n_test, n_test))
# arg_real = np.nonzero(m.Y)
# arg_fake = np.nonzero(1-m.Y)
# pred_f = m.predict_noiseless(Xtest)
# #LET'S SAVE EVERYTHING HERE
# #WHAT IS EVERYTHING?
# #THETAS, SIMULATIONS AND EXPERT LABELS IN ORDER, IDEALLY
# #GPY PARAMS
# np.save(path+'gpy_params.npy', m.param_array)
# #THETA ACQS
# np.save(path+'theta_acquisitions.npy', m.X)
# #LABELS
# np.save(path+'label_acquisitions.npy', m.Y)
# #SIMS IN ORDER
# #THETA GRID
# np.save(path+"theta_grid.npy", Xtest)
# #LIK PROXY
# np.save(path+"lik_proxy.npy", lik_proxy)
# #mean_grid_prediction
# np.save(path+"mean_pred_grid", pred_f[0])
# #var_grid_prediction
# np.save(path+"var_pred_grid", pred_f[1])
# #simulations
# #print("simulations1", np.array(simulations1))
# #np.save("simulations1.npy", np.array(simulations1))
# #np.save("simulations2.npy", np.array(simulations2))
