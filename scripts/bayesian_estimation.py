import pandas as pd
import pymc as pm
import numpy as np
import arviz as az

# Load data
df1 = pd.read_csv('dat_part1.csv')
df2 = pd.read_csv('dat_part1.csv')
data = pd.concat([df1, df2], ignore_index=True)

# Outcome and predictors 
y = data['poach'] 
X = data[["Standardized_CumRS", "Pct_of_Possible_Points_Won"]]

# Logistic model 
with pm.Model() as model:
    alpha = pm.Normal('alpha', mu=0, sd=10)
    beta = pm.Normal('beta', mu=0, sd=1, shape=2)  
    
    p = pm.invlogit(alpha + beta[0]*X["Standardized_CumRS"] + beta[1]*X["Pct_of_Possible_Points_Won"])
    
    outcome = pm.Bernoulli('outcome', p=p, observed=y)
    
    trace = pm.sample(2000, chains=2)
    
# Save trace 
az.to_netcdf(trace, 'logreg_trace.nc')

# Check trace 
az.summary(trace)


