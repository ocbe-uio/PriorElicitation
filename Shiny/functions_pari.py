import numpy as np
import GPy
import functions_veri

# =========================================================================== #
# Internal functions (called by the external functions below)                 #
# =========================================================================== #


def sample_crp(alpha, theta, n):
    membership = [1]
    for i in range(1, n):
        probs = ([(m - alpha) / (i + theta) for m in membership]
                 + [(theta + len(membership) * alpha) / (i + theta)])
        newmember = np.random.multinomial(n=1, pvals=np.array(probs)).tolist()
        if newmember[-1]:
            membership = membership + [1]
        else:
            membership = [
                membership[m] + newmember[m] for m in range(len(membership))
            ]
    membership.sort(reverse=True)
    return(membership)


def dts_acquisition_X(m, X):
    pred_noiseless_mean, pred_noiseless_var = m.predict_noiseless(
        X, full_cov=False
    )
    pred_noiseless_samples = np.random.normal(size=(2601, 1000)) \
        * np.sqrt(pred_noiseless_var) \
        + pred_noiseless_mean
    pred_labels_samples = np.mean(
        functions_veri.g_log(pred_noiseless_samples), axis=1
    )
    n_this = int(np.sqrt(np.shape(X)[0]))
    pred_label = np.reshape(pred_labels_samples, (n_this, n_this))
    copeland = np.argmax(np.sum(pred_label, axis=0))
    acq_0 = copeland
    thisX1grid = np.reshape(X[:, 1], (n_this, n_this))
    thisX0grid = np.reshape(X[:, 0], (n_this, n_this))
    X_DTS_grid = np.concatenate(
        (
            thisX0grid[copeland:copeland+1, :].T,
            thisX1grid[copeland, 0]*np.ones((n_this, 1))
        ),
        axis=1
    )
    pred_DTS_mean, pred_DTS_var = m.predict_noiseless(
        X_DTS_grid, full_cov=True
    )
    DTS_samples = np.random.multivariate_normal(
        mean=pred_DTS_mean[:, 0], cov=pred_DTS_var, size=500
    )
    DTS_samples_var = np.var(DTS_samples, axis=0)
    acq_1 = np.argmax(DTS_samples_var)
    X_acq = np.concatenate(
        (
            thisX0grid[acq_0:acq_0+1, acq_1:acq_1+1],
            thisX1grid[acq_0:acq_0+1, acq_1:acq_1+1]
        ),
        axis=1
    )
    return(X_acq)

# =========================================================================== #
# External functions (called by R)                                            #
# =========================================================================== #


def acquire_Xtest(n_test=51):  # L:73
    X1test = np.expand_dims(np.linspace(0, 1, n_test), axis=1)
    X2test = np.expand_dims(np.linspace(0, 1, n_test), axis=1)

    X1testgrid, X2testgrid = np.meshgrid(X1test, X2test)

    Xtest = np.concatenate(
        (
            np.reshape(X1testgrid, (-1, 1)),
            np.reshape(X2testgrid, (-1, 1))
        ),
        axis=1
    )
    return(Xtest)


def reshapeXY(n_init, ytrain):  # L115
    # Xtrain
    init_grid_indices = np.triu_indices(n_init)
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
    # X/Ytrainmirror
    X2grid_reshaped = np.reshape(X2traingrid[init_grid_indices], (-1, 1))
    X1grid_reshaped = np.reshape(X1traingrid[init_grid_indices], (-1, 1))
    Xtrainmirror = np.concatenate((X2grid_reshaped, X1grid_reshaped), axis=1)
    ytrainmirror = 1 - ytrain
    # Output
    Xtrainfull = np.concatenate((Xtrain, Xtrainmirror), axis=0)
    ytrainfull = np.concatenate((ytrain, ytrainmirror), axis=0)
    return(Xtrainfull, ytrainfull)


def model_fit_pari(Xtrainfull, ytrainfull):  # L122
    # Kernel
    kern = GPy.kern.Matern32(input_dim=1, active_dims=0) \
        + GPy.kern.Matern32(input_dim=1, active_dims=1)
    kern.Mat32.variance.set_prior(GPy.priors.Gamma.from_EV(1., 1.))
    kern.Mat32_1.variance.set_prior(GPy.priors.Gamma.from_EV(1., 1.))
    # Likelihood
    logit_link = functions_veri.Logit()
    lik_link = GPy.likelihoods.Bernoulli(gp_link=logit_link)
    laplace_inf = GPy.inference.latent_function_inference.Laplace()
    # Model fit
    m = GPy.models.GPClassification(
        Xtrainfull, ytrainfull, kernel=kern, likelihood=lik_link,
        inference_method=laplace_inf
    )
    m.optimize()  # first runs EP and then optimizes the kernel parameters
    return(m)


def model_update_pari(m, X_acq_opt, y_acq, i, n_opt):  # L127
    x = np.r_[m.X, X_acq_opt]
    y = np.r_[m.Y, y_acq]

    x = np.r_[x, np.flip(X_acq_opt, axis=1)]
    y = np.r_[y, 1 - y_acq]

    thiskern = m.kern.copy()
    # It seems that GPy will do some optimization
    # unless you make copies of everything

    # Likelihood
    logit_link = functions_veri.Logit()  # class Logit defined on veri script
    lik_link = GPy.likelihoods.Bernoulli(gp_link=logit_link)
    laplace_inf = GPy.inference.latent_function_inference.Laplace()

    m = GPy.models.GPClassification(
        x, y, kernel=thiskern, likelihood=lik_link,
        inference_method=laplace_inf
    )

    if (i % n_opt) == 0:
        m.optimize()
    return(m)


def acquire_X_pari(m, Xtest, acq_noise=0.1):
    thisXacq = Xtest.copy()
    X_acq_opt = dts_acquisition_X(m, thisXacq)
    X_acq_opt += np.random.normal(0, acq_noise, np.shape(X_acq_opt))
    X_acq_opt[:, 0] = np.clip(X_acq_opt[:, 0], 0, 1)
    X_acq_opt[:, 1] = np.clip(X_acq_opt[:, 1], 0, 1)
    return(X_acq_opt)


def gen_X_plots_values(X):  # L187
    members_0 = sample_crp(X[0], 0., 100)
    members_1 = sample_crp(X[1], 0., 100)
    # Random procedure below rendomizes order of plots
    bin_rand = np.random.binomial(n=1, p=.5)
    if bin_rand:  # == 1
        return(members_1, members_0)
    else:  # == 0
        return(members_0, members_1)


def calc_lik_proxy_pari(m, Xtest, n_test=51):
    lik_proxy = np.exp(m.predict_noiseless(Xtest)[0])
    loglik_proxy = m.predict_noiseless(Xtest)[0]
    loglik_proxy = np.reshape(loglik_proxy, (n_test, n_test))
    lik_proxy = np.reshape(lik_proxy, (n_test, n_test))
    return(lik_proxy)
