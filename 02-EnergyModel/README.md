# Energy Model

This energy model adapts the previously developed quasi-steady state SUSDEM residential energy model for use with a synthetic population and socio-economic characteristics to estimate household energy consumption, demand profiles, and feasible retrofit and carbon saving opportunities.

This model takes as inputs the following data:

- NEED Household Microdata: https://www.gov.uk/government/statistics/national-energy-efficiency-data-framework-need-anonymised-data-2019
- EPC Certificates from local authority of interest
- Any additional high resolution data available for calibration

## Step 1: Estimate Energy Intensity Distributions

The first step of this model involves combining national data with EPCs from local authorities to estimate a distribution for energy intensity.

The data is grouped according to the age band and property type. The NEED data is used to estimate a prior for the mean energy intensity of each group, and the EPCs for the local authority of interest are used alongside this prior to infer a posterior distribution for energy intensity.

An example of the sampled posteriors is shown below for the London Borough of Haringey, with the prior distribution and the distribution of available EPCs shown for comparison.

![image](https://user-images.githubusercontent.com/66263560/130320020-e4f37ee9-db1a-40e8-a7b4-9a97068bec3e.png)


## Step 2: Calibration

## Step 3: Retrofit Analysis
