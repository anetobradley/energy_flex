# Energy Intensity Estimation:  <!-- omit in toc -->

Here we present the steps made to clean and organize the EPC data.

> You can run this wrangling process using the [notebook version](EPC_data_wrangling.ipynb).

- [1. Data Sources](#1-epc-data)
- [2. Data Engineering Overview](#2-wrangling-process-description)
- [3. Initialisation](#3-initialisation)
  - [3.1. Import necessary modules](#31-import-necessary-modules)
  - [3.2. Defining necessary parameters](#32-defining-necessary-parameters)
  - [3.3. Defining necessary functions](#33-defining-necessary-functions)

## 1. Data Sources

> The data used for this is automatically loaded from online sources (URL and API). The only user input for this sampler is the Local Authority.

Data on the energy performance of buildings in England and Wales can be obtained from the Energy Performance Certificate (EPC) provided [here](https://epc.opendatacommunities.org/) (you will need to register to access the data).

For this work, we downloaded all available files (button `All results (.zip)`).

- EPCs issued from January 2008 up to and including 30 June 2021.

In addition this model also uses the National Energy Effiency Data

## 2. Data Engineering Overview

> A key aspect of this is to convert energy consumption to energy intensity in the NEED data and to label both datasets by typology using the same convention.

To wrangling the EPC data, the following steps were applied for each column:

1. Load NEED dataset and standardise age band numbering;
2. Assign typology labels to individual households in NEED dataset;
3. Assign a code to each EPC value following the MSM description (or the desired code/value table);
    - If the row has no value (or has a value with no match), the value -1 will be used;
4. Create a lookup dictionary;
5. Go through the entire table updating values based on the lookup dictionary;
6. Save the updated table;

## 3. Categorising Household Typologies

> A feature of this model is that it accounts for heterogeneity across typologies of household (e.g. 2000s Flat vs. 1930s Semi-dettached house). To do this requires categorising 

### 3.1. Standardise the 

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

