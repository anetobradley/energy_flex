# Data <!-- omit in toc -->

- [1. Input files](#1-input-files)
  - [1.1. Postcode Lookups](#11-postcode-lookups)
  - [1.2. Raw EPC data](#12-raw-epc-data)
- [2. Output](#2-output)
  - [2.1. Wrangled EPC data](#21-wrangled-epc-data)

## 1. Input files

### 1.1. Postcode Lookups

> [`PCD_OA_LSOA_MSOA_LAD_NOV20_UK_LU.zip`](PCD_OA_LSOA_MSOA_LAD_NOV20_UK_LU.zip)

Data for linking an MSOA code to a postcode is provided by the [Open Geography portal from the Office for National Statistics](https://geoportal.statistics.gov.uk/)

Several versions are available. Here, data from [November 2020](https://geoportal.statistics.gov.uk/datasets/postcode-to-output-area-to-lower-layer-super-output-area-to-middle-layer-super-output-area-to-local-authority-district-november-2020-lookup-in-the-uk/about) (the same data reported in the synthetic population) was used.

### 1.2. Raw EPC data

> `all-domestic-certificates.zip` (Not provided!)

Data on the energy performance of buildings in England and Wales can be obtained from the Energy Performance Certificate (EPC) provided [here](https://epc.opendatacommunities.org/) (you will need to register to access the data).

For this work, we downloaded all available files (button `All results (.zip)`).

- EPCs issued from January 2008 up to and including 30 June 2021.
- 21,440,172 Domestic EPCs
- 90 columns
- Download: 18 October 2021

## 2. Output

### 2.1. Wrangled EPC data

> [`eps_england.zip`](eps_england.zip)

- 21,360,659 wrangled EPCs
- 6 encoded columns
