from matplotlib import pyplot as plt
import numpy as np
import GPy
from GPy_logit_link import Logit

def y_sample(X):
    judgement=np.zeros((np.shape(X)[0],1))
    for i in range(np.shape(X)[0]):
        ss=np.random.binomial(n=100,p=X[i])
        simulations.append(ss)
        #THIS IS THE MAGIC INTERSECTION POINT - GIVE THE WRAPPER A SIMULATION, GET A BINARY LABEL BACK
        judgement[i]=1.*(ss>35)*(ss<65)

    return(judgement)

def bo_acquisition(m,X):
    pred_f=m.predict_noiseless(X)
    acquisition_f=pred_f[0]+2.*np.sqrt(pred_f[1])
    return(acquisition_f)

n_init=21

plotting=1

simulations=[]

Xtrain=np.expand_dims(np.linspace(0,1,n_init),axis=1)
ytrain=y_sample(Xtrain)

kern=GPy.kern.Matern32(input_dim=1)+GPy.kern.White(input_dim=1)+GPy.kern.Bias(input_dim=1)

kern.Mat32.variance.set_prior(GPy.priors.Gamma.from_EV(1.,1.))

probit_link=GPy.likelihoods.link_functions.Probit()
logit_link=Logit()

lik_link=GPy.likelihoods.Bernoulli(gp_link=logit_link)

laplace_inf = GPy.inference.latent_function_inference.Laplace()

m = GPy.models.GPClassification(Xtrain,ytrain,kernel=kern,likelihood=lik_link,inference_method=laplace_inf)

m.optimize() #first runs EP and then optimizes the kernel parameters

Xgrid=np.expand_dims(np.linspace(0,1,2001),axis=1)
pred_f=m.predict_noiseless(Xgrid)

pred_f=m.predict_noiseless(Xgrid)

if plotting:
    plt.scatter(Xtrain,ytrain)
    plt.show()

    plt.plot(Xgrid,pred_f[0])
    plt.plot(Xgrid,pred_f[0]+1.96*np.sqrt(pred_f[1]))
    plt.plot(Xgrid,pred_f[0]-1.96*np.sqrt(pred_f[1]))
    plt.show()

    plt.plot(Xgrid,bo_acquisition(m,Xgrid))
    plt.show()

n_update=100-n_init
acq_noise=0.1

n_opt=5

for i in range(n_update):
    thisXgrid=Xgrid.copy()
    X_acq=np.expand_dims(thisXgrid[np.argmax(bo_acquisition(m,thisXgrid)),:],axis=1)
    X_acq+=np.random.normal(0,acq_noise,np.shape(X_acq))
    X_acq=min(max(X_acq,0*X_acq),X_acq/X_acq)

    y_acq=y_sample(X_acq)

    x = np.r_[m.X, X_acq]
    y = np.r_[m.Y, y_acq]
    thiskern=m.kern.copy()
    m = GPy.models.GPClassification(x,y,kernel=thiskern,likelihood=lik_link,inference_method=laplace_inf) 
    if (i%n_opt)==0:
        m.optimize()

pred_f=m.predict_noiseless(Xgrid)

lik_proxy=np.exp(m.predict_noiseless(Xgrid)[0])

post_proxy=lik_proxy/(np.sum(lik_proxy*0.01))

# ASK: what are we saving files for?

#LET'S SAVE EVERYTHING HERE
#WHAT IS EVERYTHING?
#THETAS, SIMULATIONS AND EXPERT LABELS IN ORDER, IDEALLY
#GPY PARAMS
# np.save('gpy_params.npy', m.param_array)
# #THETA ACQS
# np.save('theta_acquisitions.npy', m.X)
# #LABELS
# np.save('label_acquisitions.npy', m.Y)
# #SIMS IN ORDER
# #THETA GRID
# np.save("theta_grid.npy",Xgrid)
# #LIK PROXY
# np.save("lik_proxy.npy",lik_proxy)
# #POST PROXY
# np.save("post_proxy.npy",post_proxy)
# #mean_grid_prediction
# np.save("mean_pred_grid",pred_f[0])
# #var_grid_prediction
# np.save("var_pred_grid",pred_f[1])
# #simulations
# np.save("simulations.npy",np.array(simulations))

if plotting:
    plt.plot(Xgrid,pred_f[0])
    plt.plot(Xgrid,pred_f[0]+1.96*np.sqrt(pred_f[1]))
    plt.plot(Xgrid,pred_f[0]-1.96*np.sqrt(pred_f[1]))
    plt.show()

    plt.plot(Xgrid,bo_acquisition(m,Xgrid))
    plt.show()

    plt.plot(Xgrid,lik_proxy)
    plt.show()

    plt.plot(Xgrid,post_proxy)
    plt.show()

    plt.scatter(m.X,m.Y)
    plt.show()

