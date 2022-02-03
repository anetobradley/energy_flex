# Bayesian Calibration:  <!-- omit in toc -->

Here we present the steps taken to infer a posterior energy intensity distribution by household typology, using NEED and EPC data.

- [1. Data Sources](#1-data-sources)
- [2. SUSDEM Overview](#2-susdem-overview)
- [3. Input Object Classes](#3-input-object-classes)
- [4. Data Engineering](#4-data-engineering)
- [5. Residential Energy Demand](#5-residential-energy-demand)
- [6. Bayesian Calibration using Stan](#6-bayesian-calibration-using-stan)
- [7. Notes on Outputs & Data](#7-notes-on-outputs-&-data)

## 1. Data Sources

> This calibration can be run using publically available EPC records however we would recommend obtaining a more complete record from the local authority of interest to ensure more reliable results.

Data on the energy performance of buildings in England and Wales can be obtained from the Energy Performance Certificate (EPC) provided [here](https://epc.opendatacommunities.org/) (you will need to register to access the data).

- This can include any EPCs issued from January 2008.

In addition this analysis will need a weather data file containing mean monthly temperatures as well as solar irradiance on the horizontal plane. 

>An update from the original SUSDEM Matlab package has been added to use SAP to convert the horizontal plane values to vertical plane itrradiance values in the cardinal directions.

## 2. SUSDEM Overview

> This Bayesian calibration approach is based on SUSDEM developed by Booth & Choudhary (2013). A brief overview of the approach is given here with more detail availble in the relevant published articles on SUSDEM.

This aim of this calibration step is to use a sample of household data with design parameters to calibarte our energy intensity distribution and infer distributions for uncertain building parameters which may be used in retrofit and energy flexibility analyses.

The following steps are undertaken for each of the household typologies of interest:
1. Load and process relevant data;
2. Prepare calibartion inputs `xf`,`yf`,`xc`,`yc`, and `tc`;
  - 'Field' data comes directly from base energy intensity posteriors;
  - 'Computer simulations' come from an engineering-based RdSAP calculation of energy intensity;
    - `tc` are unknown and a random sample from a uniform distribution is used as a prior.
3. Load Kennedy and O'Hagan Calibration stan model.
4. Use Stan to perform MCMC sampling for uncertain parameters.
5. Recontruct a calibrated posterior for energy intensity based on paramters from MCMC Sampling.

## 3. Input Object Classes

SUSDEM uses an object-oriented approach, where classes are defined for data objects which are required as inputs for the engineering based energy intensity estimates. This ensures consistency in the formatting of data for use in RdSAP calculations.

| Object | Variables |
| ------------- |-------------|
| Constant | Time, YearTime, kWhMJ |
| Coefficients | Eo, Et, FormFactor, Alpha, R, deltaT, FrameFactor, HeatCapacity, AirStandards, DoorSize, PI |
| Geometry | Storeys, Heights, TotalArea, Volume, GroundArea, GroundPerimeter, RoofArea, FacadeArea, EnvelopeArea |
| Envelope | ExternalSurfaces, InternalSurfaces, ShadingFactors, Walls, Glazing1, Glazing2, Doors, TotalAreas |
| Construction | ExternalWall, InternalWall, Roof, Floor, Glazing1, SolarT1, Glazing2, SolarT2, Door, ShadingDevice, ThermalMass |
| HVAC | Infiltration, NatVent, EER, COP, PumpCool, PumpHeat, DHWEfficiency, FractionHeated, TankInsulation |
| Appliances | CapitaConsumption, HouseholdConsumption, Loads |
| Lights | PowerIntensity, LEL, LCF, LELFactor |
| Occupants | Number, OccupantGain |
| Weather | ExternalTemp, GroundTemp, SolarIrr, SunsetTime |
| SetPoint | THeating, TCooling, Tpubspace, Tground |

## 4. Data Engineering

This is an important part of the script and dedicated data wrangling functions are included which prepare data to be corrctly formatted for both the bayesian calibration step, as well as the engineering based residential demand estimation.

Two functions are responsible for preparing engineering input data. 

### 4.1. IO 

```r
IO <- function(samples, designParam, posteriors, weather){
...
return(c(xf, yf, xc, yc, tc))
}
```

This function prepares the following dataframes required for the Kennedy and O'Hagan Bayesian Calibration.

| Variable | Description |
|----------|-------------|
| xf | Design Points from Field Trials (State variables*) |
| yf | Measurements from Field Trials (Energy Intensity from Base Distributions)|
| xc | Design Points for Computer Simulation (State variables* for RdSAP engineering-based model)|
| yc | Estimates from Computer Simulation (RdSAP energy intensity estimates)|
| tc | Uncertain Building Parameters (unknown but neded for RdSAP calculation - these will be inferred)|

`xf` and `xc` represent some unknown state variables under which observations took place. In this analysis we do not have any such clear variable. Instead we assume that this represents some real world condition which can be represented by a normal distribution. As this value of this is not of interest, and all values will be unitised for MCMC sampling it does not actually matter what values these take so long as they follow a normal distribution.

`yf` will be a sample of from the Base Posterior Distribution for each household typology.

`yc` will be the energy intensity estimated by the RdSAP calculation. For this `IO` calls `ResidentialEnergyDemand` (see below).

`tc` are uncertain building paramters (such as glazing U-values) which are needed for the RdSAP calculation and which are not known. Uniform priors are supplied for these, and through the calibration we shall infer the likely distribution of tehse parameters for each household typology.

### 4.2. Inputs

Inputs from the calibration dataset design parameters, and weatherfile need to be wrangled to produce the variables needed for the RdSAP calculations.

```r
Inputs <- function(Inputs1, Inputs2, Inputs3, Inputs4){
...
return(c(input_geometry, input_envelope, input_constructions, input_hvac, input_appliances, input_lights, input_occupancy, input_weather, input_SP, constants, coefficients))
}
```

This function is called by `ResidentialEnergyDemand` (see below).

## 5. Residential Energy Demand

In preparing inputs for the calibation MCMC sampling, the `IO` function calls the `ResidentialEnergyDemand` function.

```r
ResidentialEnergyDemand = function(Inputs1, Inputs2, Inputs3, Inputs4){
...
return(c(MonthlyHeatingUsage, MonthlyDHWUsage, MonthlyElectricityDemand))
}
```
## 6. Bayesian Calibration using Stan

SUSDEM uses the bayeian calibration approach outlined by Kennedy and O'Hagan (2004). This was implemented using Stan by Chong & Menberg (2019), and we have adapted their Stan model for use here.

This will be updated to work with CmdStan for better parallel processing capabilities compared to RStan.

## 7. Notes on Outputs & Data
