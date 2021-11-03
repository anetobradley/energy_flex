#------------------------------------------------------
#SUSDEM:
# STOCHASTIC URBAN SCALE DOMESTIC ENERGY MODEL
# BAYESIAN REGRESSION, CALIBRATION, AND DECISION-MAKING
# ------------------------------------------------------
# Andre Neto-Bradley 2021
# Adapted from Original MATLAB (Adam Booth and Ruchi Choudhary, 2013)
# Energy Efficient Cities Initiative (www.eeci.cam.ac.uk)
#-------------------------------------------------------
  
#-------------------------------------------------------
# ALL CODE RELATES TO CASE STUDY HOUSING STOCK
# IN SALFORD, UK
# See samples files with code
#-------------------------------------------------------
  
#--------------------------------------------------------------
# INPUTS: Energy Performance Certificate / RdSAP inputs
#         for sample dwellings
#         Weather data - monthly temperatures and irradition
#         Energy intensity posteriors from Bayesian regression
#         (See Bayesian regression Matlab files)
#
# OUTPUTS: End-use energy demands
#          Utilities (installation costs; lifetime financial savings;
#         CO2 emissions savings; thermal comfort improvement)
#--------------------------------------------------------------
  
# clear all

#-------------------------------
# CREATE EMPTY ARRAY OF STRUCTURES TO HOLD DATA (INPUTS AND OUTPUTS)
# CLUSTER HOUSING STOCK BY STRUCTURAL TYPE AND AGE
# (Five primary clusters chosen for case study housing stock)
#-------------------------------
  
# EPC inputs
# buildingData(1).inputs = []; % pre-1914 terraced houses/bungalows
# buildingData(2).inputs = []; % 1914-1945 semi-detached houses/bungalows
# buildingData(3).inputs = []; % 1945-1964 semi-detached houses/bungalows
# buildingData(4).inputs = []; % 1945-1979 flats and maisonettes
# buildingData(5).inputs = []; % 1945-1979 terraced houses/bungalows

# Total floor areas
# buildingData(1).areas = []; % pre-1914 terraced houses/bungalows
# buildingData(2).areas = []; % 1914-1945 semi-detached houses/bungalows
# buildingData(3).areas = []; % 1945-1964 semi-detached houses/bungalows
# buildingData(4).areas = []; % 1945-1979 flats and maisonettes
# buildingData(5).areas = []; % 1945-1979 terraced houses/bungalows

# End-use energy demands
# buildingData(1).Demand = []; % pre-1914 terraced houses/bungalows
# buildingData(2).Demand = []; % 1914-1945 semi-detached houses/bungalows
# buildingData(3).Demand = []; % 1945-1964 semi-detached houses/bungalows
# buildingData(4).Demand = []; % 1945-1979 flats and maisonettes
# buildingData(5).Demand = []; % 1945-1979 terraced houses/bungalows

# Utilities (installation costs; lifetime financial savings; CO2 emissions savings; thermal comfort improvement)
# buildingData(1).Utility = []; % pre-1914 terraced houses/bungalows
# buildingData(2).Utility = []; % 1914-1945 semi-detached houses/bungalows
# buildingData(3).Utility = []; % 1945-1964 semi-detached houses/bungalows
# buildingData(4).Utility = []; % 1945-1979 flats and maisonettes
# buildingData(5).Utility = []; % 1945-1979 terraced houses/bungalows

# Calibration parameter posterior samples
# buildingData(1).pvals = []; % pre-1914 terraced houses/bungalows
# buildingData(2).pvals = []; % 1914-1945 semi-detached houses/bungalows
# buildingData(3).pvals = []; % 1945-1964 semi-detached houses/bungalows
# buildingData(4).pvals = []; % 1945-1979 flats and maisonettes
# buildingData(5).pvals = []; % 1945-1979 terraced houses/bungalows

# Bayesian calibration parameters
# buildingData(1).params = []; % pre-1914 terraced houses/bungalows
# buildingData(2).params = []; % 1914-1945 semi-detached houses/bungalows
# buildingData(3).params = []; % 1945-1964 semi-detached houses/bungalows
# buildingData(4).params = []; % 1945-1979 flats and maisonettes
# buildingData(5).params = []; % 1945-1979 terraced houses/bungalows

#------------------------------------------------
# IMPORT INPUTS FOR CONSTRUCTION/DESIGN PARAMETERS
# FROM EPC INPUT DATA
# LOAD WEATHER DATA FOR REGION
#------------------------------------------------

load('SalfordEPCMarch2012.mat')
load('SalfordWeather.mat')

N = size(designParam,1) #N = number of sample dwellings
dwellingtype = designParam$DwellingType # matrix for Dwelling type
dwellingposition = designParam$DwellingPosition #matrix for Dwelling position
dwellingage = designParam$AgeBandCode #matrix for Age band of dwelling

groundfloorareas = designParam$GroundFloorArea #matrix for Ground floor area
firstfloorareas = designParam$FirstFloorArea #matrix for First floor area
secondfloorareas = designParam$SecondFloorArea #matrix for Second floor area
totalfloorareas = groundfloorareas+firstfloorareas+secondfloorareas #matrix for Total floor area

#SPECIFY NUMBER OF CLUSTERS
C = 5 # C = number of building classes (i.e. clusters) for housing stock analysis; Five for case study

#create structure of input data
#sort dwellings into clusters by building class (structural type and construction age)
for(n in 1:N){
  
  if((dwellingposition[n] == 1 || dwellingposition[n] == 2) && (dwellingage[n] == 0 || dwellingage[n] == 1)){
    buildingData(1).inputs = cat(1,buildingData(1).inputs,designParam(n,:));
    buildingData(1).areas = cat(1,buildingData(1).areas,totalfloorareas(n,:));
  }else if((dwellingposition[n] == 3) && (dwellingage[n] == 1 || dwellingage[n] == 2)){
    buildingData(2).inputs = cat(1,buildingData(2).inputs,designParam(n,:));
    buildingData(2).areas = cat(1,buildingData(2).areas,totalfloorareas(n,:));
  }else if((dwellingposition(n,1) == 3) && (dwellingage(n,1) == 3)){
    buildingData(3).inputs = cat(1,buildingData(3).inputs,designParam(n,:));
    buildingData(3).areas = cat(1,buildingData(3).areas,totalfloorareas(n,:));
  }else if((dwellingtype(n,1) == 1 || dwellingposition(n,1) == 3) && (dwellingage(n,1) == 3 || dwellingage(n,1) == 4 || dwellingage(n,1) == 5)){
    buildingData(4).inputs = cat(1,buildingData(4).inputs,designParam(n,:));
    buildingData(4).areas = cat(1,buildingData(4).areas,totalfloorareas(n,:));
  }else if((dwellingposition(n,1) == 1 || dwellingposition(n,1) == 2) && (dwellingage(n,1) == 3 || dwellingage(n,1) == 4 || dwellingage(n,1) == 5)){
    buildingData(5).inputs = cat(1,buildingData(5).inputs,designParam(n,:));
    buildingData(5).areas = cat(1,buildingData(5).areas,totalfloorareas(n,:));
  }
  
  }


#clear designParam
#clear dwellingtype
#clear dwellingposition
#clear dwellingage

#------------------------------------------------
# LOAD POSTERIORS OF ENERGY INTENSITY
# FROM BAYESIAN REGRESSION
#------------------------------------------------
# FOR GAMMA POSTERIORS
# Results from Bayesian regression analysis with a mixture of two priors,
# including errors in variables model
# See paper: Booth, Choudhary, and Spiegelhalter (2013), "A hierarchical
# Bayesian framework for calibrating micro-level models with macro-level
# data", Journal of Building Performance Simulation, DOI: 10.1080/19401493.2012.723750

# ORIGINAL SECTION HAS BEEN

# specify burn period
burn = 1000; # number of MCMC samples to discard

S1=bugs2mat('paleopriorsnoepsilon2.ind','paleopriorsnoepsilon2a.out')
gammaposteriors1(:,:) = S1.eint(burn:end,:) #eliminate initial samples as burn period

S2=bugs2mat('paleopriorsnoepsilon2.ind','paleopriorsnoepsilon2b.out')
gammaposteriors2(:,:) = S2.eint(burn:end,:) #eliminate initial samples as burn period

S3=bugs2mat('paleopriorsnoepsilon2.ind','paleopriorsnoepsilon2c.out')
gammaposteriors3(:,:) = S3.eint(burn:end,:) #eliminate initial samples as burn period

S4=bugs2mat('paleopriorsnoepsilon2.ind','paleopriorsnoepsilon2d.out')
gammaposteriors4(:,:) = S4.eint(burn:end,:); #eliminate initial samples as burn period

#create large posterior sample population from joining separate posterior chains
gammaposteriors = cat(1, gammaposteriors1,gammaposteriors2,gammaposteriors3,gammaposteriors4)

#clear gammaposteriors1
#clear gammaposteriors2
#clear gammaposteriors3
#clear gammaposteriors4
#clear S1
#clear S2
#clear S3
#clear S4

#store posterior distributions
buildingData(1).posteriors = gammaposteriors(:,2) # pre-1914 terraced houses/bungalows
buildingData(2).posteriors = gammaposteriors(:,7) # 1914-1945 semi-detached houses/bungalows
buildingData(3).posteriors = gammaposteriors(:,11) # 1945-1964 semi-detached houses/bungalows
buildingData(4).posteriors = gammaposteriors(:,13) # 1945-1979 flats and maisonettes
buildingData(5).posteriors = gammaposteriors(:,14) # 1945-1979 terraced houses/bungalows

clear gammaposteriors

% specify number of samples for the Bayesian calibration
samples = 10; 
% i.e. number of simulations and number of samples from posteriors of energy intensity

%RUN ANALYSIS FOR EACH BUILDING CLASS
%parpool(C) %run parallel analysis for each cluster
for i = 1:C

%-----------------------------------------------------
  %CALCULATE INPUTS AND OUTPUTS FOR BAYESIAN CALIBRATION
%-----------------------------------------------------
  % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  % xf: Design points corresponding to field trials
% xc,tc: Design points corresponding to computer trials
% (tc is calibration parameters, xc is known parameters)
% yf: Response from field experiments
% yc: Response from computer simulations

[xf, yf, xc, tc, yc] = IO(samples, buildingData(i).inputs, texts, buildingData(i).posteriors, weather);

%------------------------
  %RUN BAYESIAN CALIBRATION
%------------------------
  % See paper: Booth, Choudhary, and Spiegelhalter (2013), "Handling
% uncertainty in housing stock models", Building and Environment, DOI: 10.1016/j.buildenv.2011.08.016

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  % Return posterior realizations and params structure
% pvals: samples from joint posterior distribution of calibration params
% params: structure with info about parameters
[pvals, params] = gaspdriver(yf,yc,xf,xc,tc);
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  buildingData(i).pvals = pvals;
buildingData(i).params = params;

%---------------------------------------------
  % RUN RETROFIT ANALYSIS USING CALIBRATED MODEL
%---------------------------------------------
  % See paper: Booth and Choudhary (2013), "Decision making under uncertainty
% in the retrofit analysis of the UK housing stock: Implications for the
% Green Deal", Energy and Buildings, DOI: 10.1016/j.enbuild.2013.05.014

[Demand, Utility] = retrofitAnalysis(pvals, params, samples, buildingData(i).inputs, texts, weather);

buildingData(i).Demand = Demand; %End-use energy demands
buildingData(i).Utility = Utility; %Utilities (installation costs; lifetime financial savings; CO2 emissions
                                               %savings; thermal comfort improvement)

end

matlabpool close

