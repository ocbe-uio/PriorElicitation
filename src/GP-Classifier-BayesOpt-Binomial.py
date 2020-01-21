from matplotlib import pyplot as plt
import numpy as np
import GPy
from GPy_logit_link import Logit  # class inside GPY_logit_link.py
from gen_sim import y_sample, gen_sim, bo_acquisition

# TODO: move all code below to a different script or to Shiny

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

# ASK: what were we saving files for?

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