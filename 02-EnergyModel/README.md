# Energy Model

This energy model adapts the previously developed quasi-steady state SUSDEM residential energy model for use with a synthetic population and socio-economic characteristics to estimate household energy consumption, demand profiles, and feasible retrofit and carbon saving opportunities.

The model estimates energy use charactersitics and scenarios for the synthetic population produced by the DAME microsimulation model (01-ActivityModel) which generates a representative synthetic population with socio-economic charactersitics and information about normal daily activity. This model takes as inputs the following data:

- NEED Household Microdata: https://www.gov.uk/government/statistics/national-energy-efficiency-data-framework-need-anonymised-data-2019
- EPC Certificates from local authority of interest
- High resolution data available for calibration

## Main Objective

The main objectives of this model are to estimate energy intensity and building parameters of interest, thus enabling an evaluation of retrofit opportunities and their effectiveness and affordability as well as flexibilty in demand.

## Modelling Steps

### Step 1: Estimate Energy Intensity Distributions

The first step of this model involves combining national data with EPCs from local authorities to estimate a distribution for energy intensity.

The data is grouped according to the age band and property type. The NEED data is used to estimate a prior for the mean energy intensity of each group, and the EPCs for the local authority of interest are used alongside this prior to infer a posterior distribution for energy intensity.

An example of the sampled posteriors is shown below for the London Borough of Haringey, with the prior distribution and the distribution of available EPCs shown for comparison.

![image](https://user-images.githubusercontent.com/66263560/130320020-e4f37ee9-db1a-40e8-a7b4-9a97068bec3e.png)

### Step 2: Calibration

The second step of the energy modelling involves calibrating for uncertain building parameters. To do this the energy intensity distributions are used alongside a rich dataset for the area of interest which contains information about building construction and characteristics from which an engineering based energy intensity estimate (using RdSAP) can be calculated. This not only calibrates the energy intensity distribution but also provides a distribution of estimated parameter values. 

### Step 3: Retrofit & Energy Flexibility Analysis

The final step of this model evaluates the carbon saving potential and affordability of different retrofit options as well as exploring opportunities for flexibility in demand based on the activity data modelled in rhe synthetic population. The uncertain building parameter distributions infered through the calibration step enable a more realistic assessment of the uncertainty in potential costs and benefits
