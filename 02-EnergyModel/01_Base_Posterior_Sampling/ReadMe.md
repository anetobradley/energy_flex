# Energy Intensity Estimation  <!-- omit in toc -->

Here we present the steps taken to infer a posterior energy intensity distribution by household typology, using NEED and EPC data.

- [1. Data Sources](#1-data-sources)
- [2. Data Engineering Overview](#2-data-engineering-overview)
- [3. Categorising Household Typologies](#3-categorising-household-typologies)
  - [3.1. Standardise the Age Bands](#31-import-necessary-modules)
  - [3.2. Defining necessary parameters](#32-defining-necessary-parameters)
- [4. Bayesian Hierarchical Model](#4-bayesian-hierarchical-model)
- [5. MCMC Sampling using Stan](#5-mcmc-sampling-using-stan)
- [6. Notes on Data & Outputs](#6-notes-on-data-&-outputs)

## 1. Data Sources

> The data used for this is automatically loaded from online sources (URL and API). The only user input for this sampler is the Local Authority and a boolean variable which sets the typology labelling to either be age agnostic (`FALSE`) or not (`TRUE`).

Data on the energy performance of buildings in England and Wales can be obtained from the Energy Performance Certificate (EPC) provided [here](https://epc.opendatacommunities.org/) (you will need to register to access the data).

For this work, we load the 5000 most recent EPCs from the Local Authority of Interest.

- This can include any EPCs issued from January 2008.

In addition this model also uses the household level instances from the the National Energy Effiency Data (NEED). This is only not disaggregated by Local Authority.

## 2. Data Engineering Overview

> A key aspect of this is to convert energy consumption to energy intensity in the NEED data and to label both datasets by typology using the same convention.

To wrangling the EPC data, the following steps were applied for each column:

1. Load NEED dataset;
2. Assign typology labels to individual households in NEED dataset;
3. Convert NEED energy consumption to energy intensity using floor area categories;
4. Access EPCs for Local Authority of interest using API;
5. Assign NEED Age Banding to EPC instances;
6. Assign typology labels to individual households in EPC data;
7. Pass the processed NEED and EPC dataframes to RStan.

## 3. Categorising Household Typologies

> A feature of this model is that it accounts for heterogeneity across typologies of household (e.g. 2000s Flat vs. 1930s Semi-dettached house). To do this requires categorising instances in the EPC and NEED data according to the house type and age.

### 3.1. Standardise the Age Bands

The age banding across the NEED and EPC datasets needs to be homogenised before categorising typologies.

| Years | NEED Age Band|
| ------------- |-------------|
| before 1930 | 101 |
| 1930-1972 | 102 |
| 1973-1999 | 103 |
| 2000 or later | 104 |

### 3.2 Typology Parser Function

This function is used to assign each instance to one of 24 age-building type typologies of household. There are 6 defined house typologies in the NEED and EPCs (Bungalow, Detatched, End terrace, Mid terrace, Semi detached, Flat), and for each house type four typologies are defined, one for each age band.

```r
typology_parser <- function(x,y){
    if(x=="Bungalow" && y==101){type = 1}
    else if(x=="Bungalow" && y==102){type = 2}
    else if(x=="Bungalow" && y==103){type = 3}
    else if(x=="Bungalow" && y==104){type = 4}
    else if(x=="Detatched" && y==101){type = 5}
    else if(x=="Detatched" && y==102){type = 6}
    else if(x=="Detatched" && y==103){type = 7}
    else if(x=="Detatched" && y==104){type = 8}
    else if(x=="End terrace" && y==101){type = 9}
    else if(x=="End terrace" && y==102){type = 10}
    else if(x=="End terrace" && y==103){type = 11}
    else if(x=="End terrace" && y==104){type = 12}
    else if(x=="Flat" && y==101){type = 13}
    else if(x=="Flat" && y==102){type = 14}
    else if(x=="Flat" && y==103){type = 15}
    else if(x=="Flat" && y==104){type = 16}
    else if(x=="Mid terrace" && y==101){type = 17}
    else if(x=="Mid terrace" && y==102){type = 18}
    else if(x=="Mid terrace" && y==103){type = 19}
    else if(x=="Mid terrace" && y==104){type = 20}
    else if(x=="Semi detached" && y==101){type = 21}
    else if(x=="Semi detached" && y==102){type = 22}
    else if(x=="Semi detached" && y==103){type = 23}
    else if(x=="Semi detached" && y==104){type = 24}
    else{type=NA}
    }
```

## 4. Bayesian Hierarchical Model

The Energy Intensity Distribution for the Local Authority of Interest is specified as a normal distribution with a mean `E` varying by household typology `t`. National level NEED data provides a prior on hyperparameters, and EPCs for teh local authority are used to infer the local distribution of energy intensity for each typology.

The model is writen in Stan and the different blocks of the model file are explained below.

### 4.1 Model Inputs
The inputs for the energy intensity model include the NEED Data which is used as a prior, and the sample of EPCs for the local authority. Model inputs are standardised and unitised.

```stan
data {
  
  int<lower=0> N; // Number of instances in the NEED Data
  int<lower=0> M; // Number of instances in the EPC data for specific region
  int<lower=1> T; // Number of households typology groups
  vector[N] E_N; // NEED Data Energy Intensity Values
  vector[M] E_M; // LA Specific EPC Energy Intensity Values
  real sigma_N; // Standard Deviation of NEED Data Energy Intensity Values
  int<lower=1, upper=T> tn[N]; // Vector of Household Typologies for NEED Data
  int<lower=1, upper=T> tm[M]; // Vector of Household Typologies for EPC Data
  
}
```

### 4.2 Model Parameters
These are the parameters which we are looking to infer, namely the energy intensity mean for the local area and the variance. We employ a non-centered paramaterisation to improve sampling efficiency as described in the Stan User Guide (https://mc-stan.org/docs/2_19/stan-users-guide/reparameterization-section.html).

In summary we say that the distribution for Local Energy Intensity Mean `E ~ N(mu_E,sigma_E)` can be represented as `E = mu_E + sigma_E*yet` where `mu_E` is a location parameter, sigma_E is a scale parameter, and zee is a standard normal distribution (`N(0,1)`). This reprarameterisation will allow for more efficient sampling in cases with little data as explained by Betancourt and Girolami (2013).

In addition we also set a prior on the scale and location hyperparameters using the national level NEED data, (the `Eta` transformed parameter). This assumes that the Local Authority Energy Intensity Distribution comes from the National Energy Intensity Distribution for each typology.

```stan
parameters {
  
  vector[T] yet; // Posterior Energy Intensity precision term reparameterisation
  vector[T] mu_E; // Mean Energy Intensity for each Household Typology
  real<lower=0> sigma_E; // Precision term for Energy Intensity for each Household Typology
  real<lower=0> sigma; // Precision term for EPC Energy Intensities
  vector[N] zee; // Posterior Energy Intensity precision term reparameterisation
  
}

transformed parameters {
  
  vector[N] Eta;
  vector[T] E;
  
  E = mu_E + sigma_E*yet; // Reparameterisation for Local Energy Intensity Mean
  
  Eta = mu_E[tn] + sigma_E*zee; // Reparameterisation for NEED Data Prior
  

}
```

### 4.3 Model Specification
The model block defines the distribution of NEED energy intensity values `E_N`, as having a mean `Eta[tn]`, and a known precision `sigma_N` (we use a known precision term as we assume that our random sample of 50,000 households can be taken as representative of the whole population). As `E_N` and `sigma_N` are known this estimates priors for `mu_E` and `sigma_E` from the NEED data.

The energy intensity for the local authority `E` is infered for each house typology `tm` from the EPC energy intensities `E_M`.

```stan
model {
  
  zee~std_normal(); // Re-parameterised precision term
  
  E_N ~ normal(Eta[tn], sigma_N); Specifcation of 
  
  yet~std_normal(); // Re-parameterised precision term
  
  sigma~std_normal();
  
  E_M ~ normal(E[tm], sigma);
  
}
```

## 5. MCMC Sampling using Stan

### 5.1 Stan Settings

We recommend following RStan recommended settings:

```r
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
```

In addition the following Stan mcmc sampling settings used are:

```r
iter=4000, 
warmup=1000,
chains=4,
control = list(max_treedepth = 10,adapt_delta = 0.8)
```

### 5.2. Troubleshooting

The Stan documentation provides some excellent discussion and examples concerning common errors and warning messages, however there are a few specific issues encountered when using this. 

1. In some local authorities there are virtually no instances of a particular typology in the EPCs. This can lead to unreliable outputs or convergence problems. An inspection of outputs should reveal this - depending on the case it may be appropriate to disregard the distribution for the typology in question (e.g. post-2000 Bungalows in Westminster) as it will not be represented in the synthetic population.
2. Similarly the EPCs can have some erroenous data entries (for example energy intensities of tens of thousands of kWh/m2) - This too can lead to convergence problems if the sample size for a particular typology is small. In these instances it can helpful to filter out unreasonably high values (often the result of an error in inputing the EPC record in the first place).

## 6. Notes on Data & Outputs

The plot below shows en example of the outputs from the MCMC sampling, with EPC and NEED prios shown alongside the posterior.

![image](https://user-images.githubusercontent.com/66263560/130320020-e4f37ee9-db1a-40e8-a7b4-9a97068bec3e.png)
