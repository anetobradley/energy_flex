# Energy Intensity Estimation:  <!-- omit in toc -->

Here we present the steps taken to infer a posterior energy intensity distribution by household typology, using NEED and EPC data.

- [1. Data Sources](#1-data-sources)
- [2. Data Engineering Overview](#2-data-engineering-overview)
- [3. Categorising Household Typologies](#3-categorising-household-typologies)
  - [3.1. Import necessary modules](#31-import-necessary-modules)
  - [3.2. Defining necessary parameters](#32-defining-necessary-parameters)
  - [3.3. Defining necessary functions](#33-defining-necessary-functions)
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
5. 
6. Go through the entire table updating values based on the lookup dictionary;
7. Pass the processed NEED and EPC dataframes to RStan.

## 3. Categorising Household Typologies

> A feature of this model is that it accounts for heterogeneity across typologies of household (e.g. 2000s Flat vs. 1930s Semi-dettached house). To do this requires categorising 

### 3.1. Standardise the Age Bands

The age banding across the NEED and EPC datasets needs to be homogenised before categorising typologies.

| Years | NEED Age Band|
| ------------- |-------------|
| before 1930 | 101 |
| 1930-1972 | 102 |
| 1973-1999 | 103 |
| 2000 or later | 104 |

### 3.2 Typology Parser Function

This function 

```r
typology_parser <- function(x,y){
    if(x=="Bungalow" && y==101){
      type = 1
    }
    else if(x=="Bungalow" && y==102){
      type = 2
    }
    else if(x=="Bungalow" && y==103){
      type = 3
    }
    else if(x=="Bungalow" && y==104){
      type = 4
    }
    else if(x=="Detatched" && y==101){
      type = 5
    }
    else if(x=="Detatched" && y==102){
      type = 6
    }
    else if(x=="Detatched" && y==103){
      type = 7
    }
    else if(x=="Detatched" && y==104){
      type = 8
    }
    else if(x=="End terrace" && y==101){
      type = 9
    }
    else if(x=="End terrace" && y==102){
      type = 10
    }
    else if(x=="End terrace" && y==103){
      type = 11
    }
    else if(x=="End terrace" && y==104){
      type = 12
    }
    else if(x=="Flat" && y==101){
      type = 13
    }
    else if(x=="Flat" && y==102){
      type = 14
    }
    else if(x=="Flat" && y==103){
      type = 15
    }
    else if(x=="Flat" && y==104){
      type = 16
    }
    else if(x=="Mid terrace" && y==101){
      type = 17
    }
    else if(x=="Mid terrace" && y==102){
      type = 18
    }
    else if(x=="Mid terrace" && y==103){
      type = 19
    }
    else if(x=="Mid terrace" && y==104){
      type = 20
    }
    else if(x=="Semi detached" && y==101){
      type = 21
    }
    else if(x=="Semi detached" && y==102){
      type = 22
    }
    else if(x=="Semi detached" && y==103){
      type = 23
    }
    else if(x=="Semi detached" && y==104){
      type = 24
    }else{
      type=NA
    }
```

## 4. Bayesian Hierarchical Model

### 4.1 Model Specification

```stan
transformed parameters {
  
  vector[N] Eta;
  vector[T] E;
  
  E = mu_E + sigma_E*yet;
  
  Eta = mu_E[tn] + sigma_E*zee;
  

}

// The model to be estimated. We model the output
// 'y' to be normally distributed with mean 'mu'
// and standard deviation 'sigma'.
model {
  
  zee~std_normal();
  
  E_N ~ normal(Eta[tn], sigma_N);

  
  yet~std_normal();
  
  sigma~std_normal();
  
  E_M ~ normal(E[tm], sigma);
  
}
```

### 4.2 Model Inputs

### 4.3 Model Parameters

## 5. MCMC Sampling using Stan

### 5.1 Stan Settings

### 5.2. Troubleshooting

The Stan documentation provides some excellent discussion and examples concerning common errors and warning messages, however there are a few specific issues encountered when using this. 

## 6. Notes on Data & Outputs
