# SUSDEM_fns.R
# This script contains the functions required for running the ResidentialEnergyDemand function and all 
# dependencies as per the the original SUSDEM implmentation in MATLAB.

# FN: IO ########################################

IO <- function(samples, designParam, posteriors, weather){
  require(lhs)
  #..............................................
  # Perform Sensetivity Analysis using aggregate results of all properties for a single building class
  #..............................................
  
  M = samples # number of samples for computer simulation
  Q = 6 # number of calibration parameters
  S = M # number of samples from posterior distribution of energy intensity 
  N = nrow(designParam) # number of dwellings in building class EPC sample
  Z = length(posteriors) # size of the posterior distribution of energy intensity
  
  #..............................................
  # INPUTS AND RANGES FOR DWELLINGS
  #..............................................
    
  # xc : design points for controllable inputs in computer trials (m x p)
  # xc = ones(S,1); # bias function is a constant when using "virtual observations" from Bayesian regression
  # xc = zeros(S,1); # there are no control inputs when using "virtual observations" from Bayesian regression
  xc = runif(S); # random control inputs when using "virtual observations" from Bayesian regression
  
  # tc : design points for calibration parameters in computer trials (m x q)
  # Calibration parameters:
    # set-point temp; fraction heated; air leakage @50Pa; Heating system COP; window-to-wall ratio; double-glazing U-value
  tmin = c(10, 0, 1.5, 0.5, 0.15, 1.5) # minimum values for calibration parameters
  tmax = c(27, 1, 5.5, 1, 0.4, 3.5) # maximum values for calibration parameters
  
  tc = randomLHS(M,Q)%*%diag(tmax-tmin) + t(matrix(tmin,Q,M)) # Latin hypercube sampling of calibration parameters
  
  #..............................................
    
  # yc : response vector from computer simulations (m x 1)
  yc = rep(0,M); # initial vector to hold simulation results
  
  # xf : design points for fields trials (n x 1)
  #xf = ones(S,1); %bias function is a constant when using "virtual observations" from Bayesian regression
  #xf = zeros(S,1); % there are no control inputs when using "virtual observations" from Bayesian regression
  xf = runif(S); # random control inputs when using "virtual observations" from Bayesian regression
  
  # yf : response from field trials (n x 1)
  yf = rep(0,S); # initial matrix to samples from the posterior distribution of energy intensity (from the Bayesian regression)
  posteriorrow = sample(Z,S); # create a vector (Sx1) of random integers from 1 to Z
  
  #..............................................
  # CALCULATE ANNUAL ENERGY USAGE FOR DWELLINGS
  # Using random samples of inputs from ranges given above
  #..............................................
    
  #..............................................
  # VALUES (CONSTANTS) FOR ALL BUILDINGS
  #..............................................
  ShadingDevice = 1;
  DoorConstruction = 2.2;
  #..............................................
  
  #..............................................
  # GENERATE CONSTRUCTION/DESIGN INPUTS
  #..............................................
  # Building dimensions and geometry
    storeys = designParam$NoOfStoreys # vector for number of storeys
    groundfloorareas = designParam$GroundFloorArea # vector for Ground floor area
    groundfloorperimeters = designParam$GroundFloorPerimeter # vector for Ground floor perimeter
    groundfloorheights = designParam$GroundFloorHeight # vector for Ground floor height
    firstfloorareas = designParam$FirstFloorArea # vector for First floor area
    firstfloorperimeters = designParam$FirstFloorPerimeter # vector for First floor perimeter
    firstfloorheights = designParam$FirstFloorHeight # vector for First floor height
    secondfloorareas = designParam$SecondFloorArea # vector for Second floor area
    secondfloorperimeters = designParam$SecondFloorPerimeter # vector for Second floor perimeter
    secondfloorheights = designParam$SecondFloorHeight # vector for Second floor height
  
  # Physical building characteristics and design parameters
    noofrooms = designParam$NoOfRooms #matrix for Number of rooms
    wwr = designParam$WWR #matrix for Window to wall ratio
    percentagedoubleglazing = designParam$DoubleGlazingPercentageMain #matrix for Percentage double glazing
    dwellingtype = designParam$DwellingType #matrix for Dwelling type
    dwellingposition = designParam$DwellingPosition#matrix for Dwelling position
    dwellingage = designParam$AgeBandCode #matrix for Age band of dwelling
  
  # Construction details
    wallconstruction = designParam$ExternalWall1 #matrix for External wall construction type
    wallinsulation = designParam$ExternalWall2 #matrix for External wall insulation type
    floorconstruction = designParam$FloorConstruction #matrix for Floor construction type
    roofinsulation = designParam$RoofInsulation #matrix for Roof insulation thickness (mm)
  
  # HVAC, water, and lighting
    boilerefficiency = designParam$BoilerEfficiency #matrix for boiler efficiency
    primaryheating = designParam$SpaceHeating #matrix for primary space heating fuel
    secondaryheating = designParam$SecondaryHeating #matrix for secondary space heating fuel
    waterheating = designParam$WaterHeating #matrix for water heating fuel
    cylinderinsulation = designParam$CylinderInsulation #matrix for hot water tank insulation thickness (mm)
    lelpercentage = designParam$LELpercentage #matrix for low energy lighting percentage
  
  floorArea = rep(0,N); #initiate floor area matrix for N dwellings
  
  #..............................................
  # CREATE LATIN HYPERCUBE SAMPLES
  # for "hyper" parameters in 2nd order MC
  #..............................................
    
  # parameters = (singleglazingbaseline singleglazingretrofit doubleglazing thermal mass WWRlow WWRhigh capitaconsumption householdconsumption illuminancelevel LELfactor)
  muparameters = c(4.8, 2.0, 3.1, 2.6, 0.25, 0.4, 2.3, 7.5, 90, 0.25) #mean physical parameter values
  sigmaparameters = c(0.1, 0.05, 0.05, 0.05, 0.001, 0.001, 0.05, 0.15, 5, 0.001) #standard deviation of physical parameter values
  
  # MATLAB FORMULATION:: LHSparameters = lhsnorm(muparameters, diag(sigmaparameters), M) # Latin hypercube samples for physical parameters
  LHS_y <- randomLHS(M,10)
  
  t <- apply(LHS_y, 2, function(columny) qnorm(columny, 0, 1)) # Manual Reparamaterisation Trick from Stan. y ~ N(u,p) : y=u+p*z where z~N(0,1)
  
  LHSparameters <- cbind((muparameters[1]+t[,1]*sigmaparameters[1]),
                         (muparameters[2]+t[,2]*sigmaparameters[2]),
                         (muparameters[3]+t[,3]*sigmaparameters[3]),
                         (muparameters[4]+t[,4]*sigmaparameters[4]),
                         (muparameters[5]+t[,5]*sigmaparameters[5]),
                         (muparameters[6]+t[,6]*sigmaparameters[6]),
                         (muparameters[7]+t[,7]*sigmaparameters[7]),
                         (muparameters[8]+t[,8]*sigmaparameters[8]),
                         (muparameters[9]+t[,9]*sigmaparameters[9]),
                         (muparameters[10]+t[,10]*sigmaparameters[10])
                         )

  #..............................................
  # 2ND ORDER MONTE CARLO SIMULATION
  #..............................................
  # OUTER LOOP: 2nd-order uncertainty
  # choose samples of uncertain "hyper" parameters from posteriors
  #..............................................
    
  PredictedUsage = data.frame(NULL);
  #Weather = zeros(M,12,10);
  
  #specify weather
  #randomly generate weather data for 2010 scenario
  ExTemp = weather$weather[,1] #monthly average external temperature (degrees C)
  Irradiation = weather$weather[,2:10] #monthly average irradiation (W/m^2) for eight vertical orientations and horizontal plane
  
  #Weather(i,:,1) = ExTemp; % store weather data
  #Weather(i,:,2:10) = Irradiation; % store weather data
  
  for(i in 1:M){
  
  #..............................................
  # PICK ENERGY INTENSITY SAMPLE AS A "VIRTUAL OBSERVATION"
  # FROM THE POSTERIOR DISTRIBUTION
  # DERIVED FROM THE BAYESIAN REGRESSION    
  #..............................................
  s = posteriorrow[i] #choose a random row from the posterior distribution samples
  yf[i] = posteriors[s] #choose a random sample from the posterior distribution for energy intensity
  
  #..............................................
  # SPECIFY INPUTS AND CALCULATE ENERGY USE
  #..............................................
    
  # specify mean U-values, construction details, and occupant behaviour
  
  SingleGlazingbaseline = LHSparameters[i,1] #normrnd(4.8,0.1); % single glazing U-value (W/m^2K) is normally distributed around 5.3
  
  #meanDoubleGlazing = LHSparameters(i,3); %normrnd(3.1,0.05); % double glazing U-value (W/m^2K) is normally distributed around 2.1
  meanThermalMass = 1.0e+005*LHSparameters[i,4] #1.0e+005*normrnd(2.6,0.05); % thermal mass (J/m^2K) is normally distributed around 2.6e5
  
  #WWRlow = LHSparameters(i,5); %normrnd(0.25,0.001); % window to wall ratio is normally distributed around 0.23 for typical dwellings
  #WWRhigh = LHSparameters(i,6); %normrnd(0.4,0.001); % window to wall ratio is normally distributed around 0.35 for highly glazed dwellings
  
  meanCapitaConsumption = LHSparameters[i,7] #normrnd(2.3,0.05); % electric appliance consumption (kWh/person/day)
  meanHouseholdConsumption = LHSparameters[i,8] #normrnd(7.5,0.15); % electric appliance consumption (kWh/household/day)
  meanIlluminanceLevel = LHSparameters[i,9] #normrnd(90,5); % illuminance level in Lux, normally distributed around 90
  meanLELFactor = LHSparameters[i,10] #normrnd(0.25,0.001); % low energy lighting factor is normally distributed around 0.25
  
  #..............................................
  # GENERATE RANDOM INPUTS FOR CALIBRATION PARAMETERS  
  #..............................................
  
  HeatingSP = tc[i,1]
  FractionHeated = tc[i,2]
  Infiltration = tc[i,3]
  COP = tc[i,4]
  WWR = tc[i,5]
  DoubleGlazing = tc[i,6]
  
  #..............................................
  # INNER LOOP: 1st-order uncertainty
  # random variation of ALL parameters   
  #..............................................
    
  #PredictedUsage = zeros(N,1); %initiate matrix for energy consumption predictions
  
  # FOR EACH DWELLING
  for(n in 1:N){ # where N is the number of dwellings
  
  #..............................................
  # ASSIGN KNOWN INPUT PARAMETERS AND OTHER RANDOM INPUT PARAMETERS
  #..............................................
    
  # number of occupants based on number of rooms   
  NoOfRooms = noofrooms[n] #number of (heated) rooms
  
  # specify HVAC, water, and lighting
  HeatingType1 = primaryheating[n] # 1=gas, 2=electric (dual tariff), 3=electric (standard), 0 = smokeless fuel
  HeatingType2 = secondaryheating[n] # 1=gas, 2=electric, 0 = none
  WaterHeating = waterheating[n] # 1=gas, 2=electric (dual tariff), 3=electric (standard), 4 = smokeless fuel, 0 = none
  WaterTankInsulation = cylinderinsulation[n] # hot water tank insulation thickness (mm)
  
  CoolingCOP = 0 #unifrnd(2.5,3.5);
  CoolingSP = 40 #unifrnd(23,27);
  
  NatVent = runif(1,0.5,1) #natural ventilation in ACH
  
  IlluminanceLevel = rnorm(1,meanIlluminanceLevel,10) # illuminance level in Lux, normally distributed
  LELFactor = rnorm(1,meanLELFactor,0.02)# low energy lighting factor is normally distributed around 0.25
  PercentageLEL = lelpercentage[n] # percentage of lighting that is low energy
  CapitaConsumption = rnorm(1,meanCapitaConsumption,0.25) # electric appliance consumption (kWh/person/day)
  HouseholdConsumption = rnorm(1,meanHouseholdConsumption,0.5)
  
  #specify building design parameters (MATLAB UNTRANSLATED)
  #             if wwr(n,1) == 0
  #             WWR = normrnd(WWRlow,WWRlow*0.01); % window to wall ratio is normally distributed around 0.23 for typical dwellings
  #             elseif wwr(n,1) == 1
  #             WWR = normrnd(WWRhigh,WWRhigh*0.01); % window to wall ratio is normally distributed around 0.35 for highly glazed dwellings    
  #             end
  
  PercentageDoubleGlazing = percentagedoubleglazing[n] # percentage of glazing that is double glazed
  DwellingAge = dwellingage[n] # UPDATED FOR SAP 2012 0 = pre-1900, 1 = 1900-29, 2 = 1930-49, 3 = 1950-66, 4 = 1967-75, 5 = 1976-82, 6 = 1983-1990, 7 = 1991-1995, 8 = 1996-2002, 9 = 2003-2006, 10 = 2007-2011, 11 = 2012 onwards
  
  #specify U-values and construction details
  #DoubleGlazing = normrnd(meanDoubleGlazing,meanDoubleGlazing*0.05); % double glazing U-value (W/m^2K) is normally distributed
  #SingleGlazing = normrnd(meanSingleGlazing,meanSingleGlazing*0.05); % single glazing U-value (W/m^2K) is normally distributed
  
  ThermalMass = 1.0e+005*rnorm(1,meanThermalMass,meanThermalMass*0.05) # thermal mass (J/m^2K) is normally distributed
  InternalWall = runif(1,1.5,2) # internal wall U-value (W/m^2K) is uniformly distributed from 1.5 to 2.0
  
  #determine dwelling orientation
  Orientation = round(runif(1,1,8)) #orientation of building is random at 45degree intervals          
  
  BoilerEfficiency = (boilerefficiency[n])/100 # efficiency of space heating boiler (divided by 100 to scale to 0-1)
  
  SingleGlazing = rnorm(1,SingleGlazingbaseline,SingleGlazingbaseline*0.05) # single glazing U-value (W/m^2K) is normally distributed around 2.1
  
  ExternalWall1 = wallconstruction[n] # wall construction type; 0 = cavity, 1 = solid brick, 2 = system built, 3 = timber frame
  ExternalWall2 = wallinsulation[n] # wall insulation type; 0 = unknown, 1 = as built, 2 = external, 3 = filled cavity, 4 = not applicable 
  FloorConstruction = floorconstruction[n] # floor construction type; 0 = unknown, 1 = solid, 2 = suspended not timber, 3 = suspended timber
  RoofInsulation = roofinsulation[n] # roof insulation thickness in mm (retofit - normrnd(270,10))
  
  #specify floor heights, areas, and perimeters, and number of floors
  FloorHeights = c(groundfloorheights[n],firstfloorheights[n],secondfloorheights[n]) #vector of floor heights
  FloorAreas = c(groundfloorareas[n],firstfloorareas[n],secondfloorareas[n]) #vector of floor areas
  FloorPerimeters = c(groundfloorperimeters[n],firstfloorperimeters[n],secondfloorperimeters[n]) #vector of floor perimeters
  NoOfStoreys = storeys[n] # number of storeys (floors)
  floorArea[n] = sum(FloorAreas) # store total floor area for each dwelling
  
  #number of occupants based on total floor area (m^2); see SAP 2012 (table 1b)
  HouseholdNumber = (1 + 1.76*(1 - exp(-0.000349*(floorArea[n]-13.9)^2)) + 0.0013*(floorArea[n] - 13.9))
  
  #determine dwelling position and type
  DwellingType = dwellingtype[n] # 1 = flat, 2 = house, 3 = maisonette, 0 = bungalow
  DwellingPosition = dwellingposition[n] # 0 = detached, 1 = end-terrace, 2 = mid-terrace, 3 = semi-detached, 4 = ground-floor, 5 = mid-floor, 6 = top-floor
  
  GlazingAreaLookup = data.frame(NULL)
  #FROM SAP 2012, Table S4 **UPDATE FROM 2009 - NEW DWELLING AGE BANDS I,J,K,L
  GlazingAreaLookup[1:3,1] = 0.122*floorArea[n]+6.875 #age band A-C, house or bungalow
  GlazingAreaLookup[1:3,2] = 0.0801*floorArea[n]+5.58 #age band A-C, flat or maisonette            
  GlazingAreaLookup[4,] = c((0.1294*floorArea[n]+5.515), (0.0341*floorArea[n]+8.562)) #age band D, house or bungalow / flat or maisonette
  GlazingAreaLookup[5,] = c((0.1239*floorArea[n]+7.332), (0.0717*floorArea[n]+6.560)) #age band E, house or bungalow / flat or maisonette
  GlazingAreaLookup[6,] = c((0.1252*floorArea[n]+5.520), (0.1199*floorArea[n]+1.975)) #age band F, house or bungalow / flat or maisonette
  GlazingAreaLookup[7,] = c((0.1356*floorArea[n]+5.242), (0.051*floorArea[n]+4.554)) #age band G, house or bungalow / flat or maisonette
  GlazingAreaLookup[8,] = c((0.0948*floorArea[n]+6.534), (0.0813*floorArea[n]+3.744)) #age band H, house or bungalow / flat or maisonette
  GlazingAreaLookup[9,] = c((0.1382*floorArea[n]-0.027), (0.1148*floorArea[n]+0.392)) #age band I, house or bungalow / flat or maisonette
  GlazingAreaLookup[10:12,1] = 0.1435*floorArea[n]-0.403 #age band A-C, house or bungalow
  GlazingAreaLookup[10:12,2] = 0.1148*floorArea[n]+0.392 #age band A-C, flat or maisonette            
  
  if(DwellingType == 1 || DwellingType == 3){
    GlazingArea = GlazingAreaLookup[DwellingAge+1,2]
  } #for flats and maisonettes
  else if(DwellingType == 0 || DwellingType == 2){
    GlazingArea = GlazingAreaLookup[DwellingAge+1,1]
  } #for houses and bungalows
   
  if(wwr[n] == 1){
    GlazingArea = GlazingArea*1.25 #increase glazing area by 25% for highly glazed dwelling
  } 
  
  # Create and populate input matrices
  Inputs1 = data.frame(NoOfRooms,NoOfStoreys,WWR,PercentageDoubleGlazing,RoofInsulation,PercentageLEL,HeatingSP,CoolingSP,COP,WaterTankInsulation,FractionHeated,BoilerEfficiency,CoolingCOP,NatVent,GlazingArea)
  Inputs2 = data.frame(DwellingType,DwellingPosition,Orientation,FloorConstruction,ExternalWall1,InternalWall,DoorConstruction,ThermalMass,IlluminanceLevel,ShadingDevice,Infiltration,HeatingType1,HeatingType2,WaterHeating,SingleGlazing,DoubleGlazing,LELFactor,HouseholdNumber,CapitaConsumption,ExternalWall2,DwellingAge,HouseholdConsumption)
  Inputs3 = data.frame(FloorAreas,FloorHeights,FloorPerimeters)
  Inputs4 = data.frame(ExTemp,Irradiation)
  
  # WORKS UP TO HERE NOW 24/08/2021 ####
  
  # Calculates space heating, hot water, electrical, and cooling demand for each month (baseline - 2010)
  [spaceHeating, DHW, Electricity] =  ResidentialEnergyDemand(Inputs1, Inputs2, Inputs3, Inputs4); # for each dwelling
  
  enduseDemand = [spaceHeating DHW Electricity];
  # PerUnitUsage = (sum(sum(enduseDemand,2),1))./floorArea(n,1); % annual energy demand (kWh/m^2/year)
  
  # PredictedUsage(i,n) = PerUnitUsage; % populates energy usage vector
  PredictedUsage(i,n) = (sum(sum(enduseDemand,2),1)); # annual energy demand (kWh/year)
  
  }
  
  yc(i,1) = (sum(PredictedUsage(i,:)))/(sum(floorArea)); #average energy use per m^2 for dwellings for given sample of inputs
  

  }
  
}


# FN: ResidentialEnergyDemand ###################
# Model the monthly end-use energy demand of a single residential dwelling
# Based on SAP2009 / CEN-ISO method and standards (see EN-13790)

# INPUTS
# Inputs1 = [NoOfRooms NoOfStoreys WWR PercentageDoubleGlazing RoofInsulation PercentageLEL HeatingSP CoolingSP COP WaterTankInsulation FractionHeated BoilerEfficiency CoolingCOP NatVent GlazingArea];
# Inputs2 = [DwellingType DwellingPosition Orientation FloorConstruction ExternalWall1 InternalWall DoorConstruction ThermalMass IlluminanceLevel ShadingDevice Infiltration HeatingType1 HeatingType2 WaterHeating SingleGlazing DoubleGlazing LELFactor HouseholdNumber CapitaConsumption ExternalWall2 DwellingAge HouseholdConsumption];
# Inputs3 = [FloorAreas FloorHeights FloorPerimeters];
# Inputs4 = [ExTemp Irradiation];

# OUTPUTS
# Montly end-use energy demands (space heating, DHW, electricity)

ResidentialEnergyDemand = function(Inputs1, Inputs2, Inputs3, Inputs4){
# SAP 2009 / CEN-ISO RESIDENTIAL ENERGY DEMAND FOR A SINGLE DWELLING
#..............................................
    
DwellingType = Inputs2[1,1]
DwellingPosition = Inputs2[1,2]
    
if((DwellingType == 2 || DwellingType == 0) && (DwellingPosition == 4 || DwellingPosition == 5 || DwellingPosition == 6)){
  stop('Dwelling Type and Dwelling Position are incompatible')
}
else if((DwellingType == 1 || DwellingType == 3)  && (DwellingPosition == 0 || DwellingPosition == 1 || DwellingPosition == 2 || DwellingPosition == 3)){
  stop('Dwelling Type and Dwelling Position are incompatible')
}
     

    # NEED TO ADAPT THIS ONCE WORKING
    #Create objects with dwelling/system/occupant properties; based on EPC inputs and assumptions
    #  (geometry, envelope, constructions, hvac, appliances, lights, occupancy, weather, SP, Constants, Coefficients) =
    Outputs <- Inputs(Inputs1, Inputs2, Inputs3, Inputs4); #calls input file and populates input data
    
    input_geometry <- Outputs[[1]]
    input_envelope <- Outputs[[2]]
    input_constructions <- Outputs[[3]]
    input_hvac <- Outputs[[4]]
    input_appliances <- Outputs[[5]]
    input_lights <- Outputs[[6]]
    input_occupancy <- Outputs[[7]]
    input_weather <- Outputs[[8]]
    input_SP <- Outputs[[9]]
    input_Constants <- Outputs[[10]]
    input_Coefficients <- Outputs[[11]]
    
    
    TimeLength = nrow(input_Constants@Time) #creates variable that is equal to the number of timesteps
    #e.g. for monthly timesteps over a year, TimeLength = 12 (12 months in a year)
    #e.g. for hourly timesteps over a day, TimeLength = 24 (24 hours in a day)
    #Default is monthly timesteps
    DaysPerMonth=1./input_Constants@Time[,3]; #calculates days per month
    
    Temps = Temperature(input_weather@ExternalTemp, input_weather@GroundTemp, input_SP@THeating, input_SP@TCooling, TimeLength, DwellingType, DwellingPosition);
    Toh = matrix(Temps[[1]],nrow=4)
    Toc = matrix(Temps[[2]],nrow=4)
    #populates matrix of external temperatures / boundary temperatures for heating and cooling periods
    #based on dwelling type and dwelling position
    #matrix order is:
      #[external temperature for external walls; internal temperature of public spaces for internal walls;
        #temperature above dwelling (either external or internal depending on dwelling type/location);
        #temperature below dwelling (either external or internal depending on dwelling type/location)]
    
    Ht = CondCoefficient (input_constructions@ExternalWall, input_constructions@InternalWall, input_constructions@Glazing1, input_constructions@Glazing2, input_constructions@Door, input_constructions@Roof, input_constructions@Floor, input_envelope@Walls, input_envelope@Glazing1, input_envelope@Glazing2, input_envelope@Doors, input_geometry@RoofArea, input_geometry@GroundArea, input_envelope@ExternalSurfaces, input_envelope@InternalSurfaces) 
    #calculates conduction heat transfer coefficient (see SAP 2012, Appendix K)
    
    Qcond = ConductionLoss(Ht, input_SP@THeating, input_SP@TCooling, Toh, Toc, input_Constants@Time[,1]);
    QcondH = matrix(Qcond[1:96],nrow=12)
    QcondC = matrix(Qcond[97:192],nrow=12)
    #calculates conduction losses and outputs monthly values and yearly total (see ISO 52016-1:2017 which supercedes EN-13790:2008)
    #for heating and cooling periods
    #Values given are in MJ
    
    Hv = VentCoefficient (input_hvac@NatVent, input_hvac@Infiltration, input_Coefficients@HeatCapacity, input_geometry@EnvelopeArea, input_geometry@Volume);
    # Calculates ventilation heat transfer coefficient for heating and cooling (see ISO 52016-1:2017 which supercedes EN-13790:2008)
    # periods
    
    Qvent = VentilationLoss (input_weather@ExternalTemp, input_SP@THeating, input_SP@TCooling, Hv[1], Hv[2], input_Constants@Time[,1])
    QventH = matrix(Qvent[1:12],nrow=12)
    QventC = matrix(Qvent[13:24],nrow=12)
    # calculates ventilation losses and outputs monthly values and yearly total (see ISO 52016-1:2017 which supercedes EN-13790:2008)
    # for heating and cooling periods
    # Values given are in MJ
    
    Qsolar = SolarGains (input_envelope@Glazing1, input_envelope@Glazing2, input_envelope@Walls, input_geometry@RoofArea, input_constructions@SolarT1, input_constructions@SolarT2, input_constructions@ExternalWall, input_constructions@Roof, input_Coefficients@Eo, input_Coefficients@Alpha, input_Coefficients@R, input_Coefficients@deltaT, input_envelope@ShadingFactors, input_constructions@ShadingDevice, input_Coefficients@FormFactor, input_Coefficients@FrameFactor, input_weather@SolarIrr, input_Constants@Time[1:12,1],DwellingPosition,input_geometry@TotalArea);
    Qsol = matrix(Qsolar[1:12],nrow=12)
    C2 = Qsolar[13]
    # calculates solar gains (see SAP 2012)
    # estimate due to contributions from transmission through glazing and thermal radiation from envelope
    # outputs monthly values and yearly total
    
    #Qdhw = DHWLoad (39.5, 90.2, 1.49, geometry.TotalArea, 50, Constants.Time(:,3)); #monthly energy demand for hot water in MJ
    QDHW = DHWLoad (input_occupancy@Number, input_Constants@Time[,3], input_hvac@TankInsulation, input_Constants@kWhMJ) #monthly energy demand for hot water in MJ
    Qdhw = matrix(QDHW[1:12],nrow=12)
    Qdhw_gain = matrix(QDHW[13:24],nrow=12)
    # calculates domestic hot water consumption and internal gains due to DHW (see SAP 2012, BRE)
    # outputs monthly values and yearly total in MJ
    
    # Qlights = LightingLoad (lights.PowerIntensity, lights.LEL, lights.LELFactor, lights.LCF, geometry.TotalArea, weather.SunsetTime, Constants.Time(:,3), Constants.kWhMJ);
    Qlights = LightingLoad (input_lights@PowerIntensity, input_lights@LEL, input_lights@LELFactor, input_lights@LCF, input_geometry@TotalArea, input_occupancy@Number, C2, input_weather@SunsetTime, input_Constants@Time[,3], input_Constants@kWhMJ)
    # calculates power consumption and internal gains due to lighting (BASED ON SAP 2012, APPENDIX L1)
    # outputs monthly values and yearly total in MJ
    
    # This may need to be adjusted based on occupancy data from synthetic population.
    Qocc = OccupantLoad (input_occupancy@Number, input_occupancy@OccupantGain, input_Constants@Time[,1])
    # calculates internal gains due to occupants (see SAP 2012, Table 5)
    # outputs monthly values and yearly total in MJ
    
    Qapp = ApplianceLoad (input_geometry@TotalArea, input_occupancy@Number, input_Constants@Time[,3], input_Constants@kWhMJ)
    #Qapp = ApplianceLoad (appliances.HouseholdConsumption, appliances.CapitaConsumption, occupancy.Number, Constants.Time(:,3), Constants.kWhMJ);
    # calculates power consumption and internal gains due to appliances (based on SAP 2009, Appendix L2)
    # outputs monthly values and yearly total in MJ
    
    Qint = InternalGains (Qlights, Qapp, Qocc, Qdhw_gain, occupancy.Number, Constants.Time);
    #Qint = InternalGains (Qlights, Qapp, Qocc, hvac.FractionHeated, geometry.TotalArea, Constants.Time);
    # calculates internal gains in MJ/month (based on SAP 2009, table 5)
    # estimate based on: lighting loads, appliance loads, occupants, floor area, and fraction of the space/time occupied
    
    #..............................................
      #CALCULATE GAIN/LOSS RATIOS (see EN 13790)
    #for heating period:
      TotalHeatGain = Qsol + Qint;
    
    TotalHeatLossH = QcondH + QventH;
    
    HeatGainRatio = zeros(TimeLength, 1); #creates vector for varying heat gain ratio
    
    HeatGainRatio(:,1) = TotalHeatGain(:,1)./TotalHeatLossH(:,1); #calculates the heat gain ratio vector
    
    TotalHeatLossC = QcondC + QventC;
    
    HeatLossRatio = zeros(TimeLength, 1); #creates vector for varying heat loss ratio
    
    HeatLossRatio (:,1) = TotalHeatLossC(:,1)./TotalHeatGain(:,1); #calculates the heat loss ratio vector
    
    [UFgain, UFloss] = UtilisationFactors (HeatGainRatio, HeatLossRatio, constructions.ThermalMass, geometry.TotalArea, Ht, Hv);
    # calculates the gain utilisation factor and the loss utilisation factor
    #..............................................
      
      #SPACE HEATING:
      
      MonthlyHeatingDemandMJ = (hvac.FractionHeated)*(TotalHeatLossH - diag(TotalHeatGain)*UFgain); #monthly heating demand in MJ (accounting for fraction of space/time heated)
    
    MonthlyHeatingUsage = MonthlyHeatingDemandMJ*(1/(Constants.kWhMJ))*(1/(hvac.COP)); #monthly heating usage in kWh (heating demand / COP)
    
    HeatingDemandperUnit = MonthlyHeatingUsage*(1/geometry.TotalArea); #monthly heating usage in kWh/m^2 floor area
    
    DailyHeatingUsage = diag(DaysPerMonth)*MonthlyHeatingUsage; #converts monthly heating usage into daily heating usage in kWh
    
    sum(HeatingDemandperUnit); #total yearly heating usage per unit area(kWh/year/m2;
                                                                         
     sum(MonthlyHeatingUsage); #total yearly heating usage (kWh/year)
     
     #..............................................
       
       #DHW:
       
       #calculate water heating efficiency (based on SAP 2009)
     waterEfficiency = zeros(12,1);
     for i=1:12
     if hvac.DHWEfficiency == 1 #if boiler is electric
     waterEfficiency(i,1) = 1;  # boiler efficiency = 1;
     else # if boiler is gas   
     waterEfficiency(i,1) = (MonthlyHeatingDemandMJ(i,1) + Qdhw(i,1))/(MonthlyHeatingDemandMJ(i,1)/hvac.COP + Qdhw(i,1)/hvac.DHWEfficiency);    
     end   
     end
     
     MonthlyDHWUsage = Qdhw*(1/(Constants.kWhMJ))./waterEfficiency; #monthly energy usage for DHW in kWh
     #MonthlyDHWUsage = Qdhw*(1/(Constants.kWhMJ))*(1/(hvac.DHWEfficiency)); #monthly energy usage for DHW in kWh
     sum(MonthlyDHWUsage);
     DailyDHWUsage = diag(DaysPerMonth)*MonthlyDHWUsage; #converts monthly DHW usage into daily DHW usage in kWh
     
     #..............................................
       
       #ELECTRICITY:
       
       MonthlyElectricityDemand = (Qapp+Qlights)*(1/(Constants.kWhMJ)); #monthly electricity demand in kWh
     
     DailyElectricityDemand = diag(DaysPerMonth)*MonthlyElectricityDemand; #converts monthly electricity demand into daily heating demand in kWh
     
     sum(MonthlyElectricityDemand);
     
     #..............................................
       
       #COOLING:
       
       TotalCoolingDemandMJ = TotalHeatGain - diag(TotalHeatLossC)*UFloss; #monthly cooling demand in MJ
     
     if hvac.EER ~=0 #i.e. cooling system is present
     TotalCoolingUsage = TotalCoolingDemandMJ*(1/(Constants.kWhMJ))*(1/(hvac.EER)); #monthly cooling demand in kWh/day
     elseif hvac.EER == 0 #i.e. no cooling system is present
     TotalCoolingUsage = TotalCoolingDemandMJ*0;
     end
     
     sum(TotalCoolingUsage); #total yearly cooling demand (kWh/year)
     
     DailyCoolingUsage = diag(DaysPerMonth)*TotalCoolingUsage; #converts monthly cooling demand into daily heating demand in kWh
     
     #..............................................
       
       #TOTAL:
       
       TotalEnergyUsage = DailyHeatingUsage + DailyCoolingUsage + DailyElectricityDemand + DailyDHWUsage; #total daily energy usage in kWh/day
     
     EnergyUsageperUnit = TotalEnergyUsage*(1/geometry.TotalArea); #total daily energy usage in kWh/m^2/day
     
    ##########!!!!!!!!! YearlyEnergyUsageperUnit = EnergyUsageperUnit'*Constants.Time(:,3); # total yearly energy usage kWh/m^2/year

YearlyEnergyUsage = YearlyEnergyUsageperUnit*geometry.TotalArea; # total yearly energy usage kWh/year

return(c(MonthlyHeatingUsage, MonthlyDHWUsage, MonthlyElectricityDemand))
     
     }


# subFN: Inputs ---------------------------------
# Function that takes inputs from residential UKMap Energy data and condenses to a table of inputs for 
# Use in estimating demand for calibration.
Inputs <- function(Inputs1, Inputs2, Inputs3, Inputs4){
  # Input file for residential energy demand model (based on SAP 2009 and CEN-ISO, EN 13790)
  # Includes building geometry, envelope area, construction details, and building system information
  
  constants = new("Constants") #calls constants class
  coefficients = new("Coefficients") #calls coefficients class
  input_geometry = geometry(Inputs1[1,2], Inputs3[,1], Inputs3[,2], Inputs3[,3]) # creates geometry object and populates it
  input_envelope = envelope(input_geometry@FacadeArea, Inputs2[1,2], Inputs2[1,3], Inputs1[1,3], Inputs1[1,4], coefficients@DoorSize, Inputs1[1,15]) # creates envelope object and populates it
  input_constructions = constructions(Inputs2[1,5],Inputs2[1,20], Inputs2[1,21],Inputs2[1,6], Inputs2[1,15], Inputs2[1,16], Inputs1[1,5], Inputs2[1,4], Inputs2[1,7], Inputs2[1,10], Inputs2[1,8], Inputs2[1,1], Inputs2[1,2],input_geometry@GroundArea, input_geometry@GroundPerimeter) # creates constructions object and populates it
  input_hvac = hvac(Inputs2[1,11],Inputs1[1,14],Inputs1[1,13],Inputs1[1,9],Inputs1[1,12],Inputs2[1,12],Inputs2[1,13],Inputs2[1,14],Inputs1[1,10],1,2,Inputs2[1,2],Inputs1[1,11],Inputs2[1,21]) # creates HVAC object and populates it
  input_appliances = appliances(Inputs2[1,19],Inputs2[1,22]) #creates appliances object and populates it
  input_lights = lights(Inputs2[1,9],coefficients@PI,Inputs1[1,6],1, Inputs2[1,17]) #creates lighting object and populates it
  input_occupancy = occupancy(Inputs2[1,18]) #creates occupancy profile object and populates it
  
  input_weather = weather(t(Inputs4[,1]),Inputs4[,c(2:length(colnames(Inputs4)))], c(17,17,18,18,18,19,19,19,18,18,17,17)) #creates weather object and populates it
  input_SP = SP(Inputs1[1,7],Inputs1[1,8],16); #creates set-point object and populates it


return(c(input_geometry, input_envelope, input_constructions, input_hvac, input_appliances, input_lights, input_occupancy, input_weather, input_SP, constants, coefficients))
  #### Translated to here.
}


  
# subFN: Temperatures ################################
  
Temperature <-  function(Text, Tground, SPheat, SPcool, TimeLength, DwellingType, DwellingPosition){
  #Calculates the external/boundary temperatures for a dwelling
  #  i.e. temperatures for external/internal walls, roof, ceiling, floor,
  #  ground, etc.
  #  Toh are boundary temperatures for heating period
  #  Toc are boundary temperatures for cooling period
  
  if(DwellingType == 0 || DwellingType == 2 || DwellingPosition == 4){
    TbelowH = rep(1,TimeLength)*diag(Tground); #temperature below is ground temperature (specified in weather file)
    TbelowC = rep(1,TimeLength)*diag(Tground);
    }# if dwelling is bungalow, house, or ground floor flat/maisonette
  else{
    TbelowH = rep(1,TimeLength)*SPheat; # if dwelling is flat/maisonette (mid-floor or top-floor)
    TbelowC = rep(1,TimeLength)*SPcool; # temperature below is internal temperature of heating/cooling set point
  }
    
  if(DwellingType == 0 || DwellingType == 2 || DwellingPosition == 6){
    TaboveH = Text; # temperature above is external temperature (specified in weather file)
    TaboveC = Text;
  } # if dwelling is bungalow, house, or top floor flat/maisonette
  else{
    TaboveH = rep(1,TimeLength)*SPheat; # if dwelling is flat/maisonette (ground-floor or mid-floor)
    TaboveC = rep(1,TimeLength)*SPcool; # temperature above is internal temperature of heating/cooling set point
  }
  
  TintH = rep(1,TimeLength)*SPheat; #internal spaces (i.e. neighbouring spaces) are at the set point temperature
  TintC = rep(1,TimeLength)*SPcool;
  
  Toh = as.data.frame(matrix(c(Text, TintH, TaboveH, TbelowH)))
  Toc = as.data.frame(matrix(c(Text, TintC, TaboveC, TbelowC)))

  return(c(Toh,Toc))#Toc
  
}


# subFN: CondCoefficient ############################

CondCoefficient <- function(Uew, Uiw, Ug1, Ug2, Udoor, Uroof, Ufloor, Aw, Ag1, Ag2, Adoor, Aroof, Afloor, SurfacesExt, SurfacesInt){
  #INCLUDING THERMAL BRIDGING
  
  # based on SAP 2012, Appendix K where detail of thermal bridge is unknown
  # Htb = y x sigma(Aexp)
  # Ux = U-value (W/m^2K) of component x
  # Ax = Area (m^2) of component x
  # Surface = vector of surfaces (1 or 0) by orientation (N,NE...W,NW)
  y = 0.15
  
  HtExt = ((y+Uew)*Aw + (y+Ug1)*Ag1 + (y+Ug2)*Ag2 + (y+Udoor)*Adoor)*(SurfacesExt) #calculates Ht for vertical external surfaces (walls, glazing, doors)
  
  HtInt = (Uiw*Aw + Ug1*Ag1 + Ug2*Ag2 + Udoor*Adoor)*(SurfacesInt) #calculates Ht for vertical internal surfaces (walls, glazing, doors)
  
  HtRoof = (y+Uroof)*Aroof #calculates Ht for horizontal surfaces (roof/ceiling, floor)
  
  HtFloor = (y+Ufloor)*Afloor
  
  Ht = as.matrix(data.frame("HtExt"=c(HtExt),"HtInt"=c(HtInt), "HtRoof"=c(HtRoof), "HtFloor"=c(HtFloor))) #matrix of conduction heat transfer coefficients

  return(Ht)
}
  
  
# subFN: ConductionLoss #############################
  #Calculates trasmission losses for individual dwelling for heating and
  #cooling
ConductionLoss <- function(Ht, Tih, Tic, Toh, Toc, TimeStep){
  T = diag(TimeStep); #creates diagonal matrix out of timesteps (seconds per month)
  QcondH = T%*%t(Ht%*%(Tih-Toh)); #calculates heating and cooling conduction losses based on Q=t*Ht*deltaT
  QcondC = T%*%t(Ht%*%(Tic-Toc)); #outputs monthly values in MJ
  
  colSums(QcondH); #outputs yearly total in MJ
  colSums(QcondC);
  
  return(c(QcondH,QcondC))
}
  
# subFN: VentCoefficient ############################
# Calculates ventilation heat transfer coefficient for heating and 
# cooling (see EN-13789) periods

VentCoefficient <- function(Unat, Uinf, hc, EnvelopeArea, Volume){
  #Calculates the ventilation heat transfer coefficient
  #   Heat coefficient for ventilation based on infiltration, natural
  #   ventilation, mechanical ventilation, and any heat recovery
  
  AirRequired = 0.3*Volume*1000/3600 #calculates air required for decent air standards (l/s)
  # from EN ISO 13789:2007
  # Vmin = Volume*0.3 (m^3/h) * 1000/3600 (l/s)/(m^3/h)
  
  #for heating period:
    Infiltration = Uinf*EnvelopeArea #calculates Infiltration rate (l/s) during heating period
  
  if(Infiltration<AirRequired){
    NatVentHeating = AirRequired-Infiltration;
  }
  else{
    NatVentHeating = 0;
  }
  
  Uheat = Infiltration + NatVentHeating #total air flow to be heated in l/s
  
  Hvh = hc*Uheat #ventilation heat transfer coefficient for heating period
  
  #for cooling period:
    
  #Unat is in ACH
  Ucool = Unat*Volume*1000/3600 #total air flow for cooling in l/s
  #conversion from m^3/h to l/s
  
  Hvc = hc*Ucool
  
  Hv = c(Hvh, Hvc)
  
  return(Hv)

}
  
# subFN: VentilationLoss ############################
# calculates ventilation losses and outputs monthly values and yearly total (see EN-13790)
# for heating and cooling periods
# Values given are in MJ
VentilationLoss <- function(To, Tih, Tic, Hvh, Hvc, TimeStep){
  #Calculates ventilation losses for individual dwelling for heating and
  #cooling periods
  
  Tx = diag(TimeStep) #creates diagonal matrix out of timesteps (seconds per month)
  
  QventH = (Hvh*(Tih-To))%*%Tx #calculates heating and cooling ventilation losses based on Q=t*Hv*deltaT
  QventC = (Hvc*(Tic-To))%*%Tx #gives monthly values in MJ
  
  sum(QventH) #outputs yearly total in MJ
  sum(QventC)
  
return(c(QventH, QventC))
  
}
  
# subFN: SolarGains #################################
# calculates solar gains (see SAP2009)
# estimate due to contributions from transmission through glazing and thermal radiation from envelope
# outputs monthly values and yearly total
SolarGains <- function(Ag1, Ag2, Aw, Aroof, ST1, ST2, Uew, Uroof, Eo, Alpha, Rext, deltaT, ShadingCorrection, ShadingReduction, FormFactor, FrameFactor, SolarIrradiation, TimeStep, DwellingPosition, FloorArea){
  # Calculates solar gains
  # Based on solar collection and thermal emissivity for windows, walls, and roof
  # Ax = area (m^2) of component x
  # Ux = U-value (W/m^2K) of component x
  # 1 = single glazing ; 2 = double glazing
  
  #for vertical surfaces (walls and glazing):
  gg = 0.9*c(ST1, ST2) #ST = solar transmittance
  
  EffectiveSolarAreaTrans = (1-FrameFactor)*ShadingReduction%*%diag(gg)%*%(rbind(Ag1, Ag2))*(ShadingCorrection) #calculates the effective solar collection area for windows
  
  EffectiveSolarAreaOpaq = Rext*Alpha*Uew*Aw*(ShadingCorrection) #calculates effective solar collection area for opaque surfaces (external walls)
  
  ThermalRadiation = deltaT*Rext*5*Eo*Uew*Aw%*%t(ShadingCorrection) #calculates thermal radiation to the sky
  
  TimeLength = length(TimeStep) #creates variable that is equal to the number of timesteps
  #e.g. for monthly timesteps over a year, TimeLength = 12 (12 months in a year)
  #e.g. for hourly timesteps over a day, TimeLength = 24 (24 hours in a day)
  
  NoOfSurfaces = length(ShadingCorrection) #creaes a variable equal to number of vertical surfaces
  
  SolarGainWindowsWatts = matrix(0,TimeLength, NoOfSurfaces) #creates matrix with time and space dimensions
  for(m in 1:TimeLength){
    SolarGainWindowsWatts[m, 1:NoOfSurfaces] = as.matrix((SolarIrradiation[m,1:NoOfSurfaces])*(EffectiveSolarAreaTrans)) #calculates monthly solar gain for windows in Watts
  }
  
  SolarGainWindows = t(SolarGainWindowsWatts)%*%diag(TimeStep) # in MJ
  
  TotalWindowGain = t(colSums(SolarGainWindows)) #calculates total solar gain for windows in MJ per month #### CHECKED TO HERE 21/10/2021 5:42pm
  
  SolarGainWallsWatts = matrix(0,TimeLength, NoOfSurfaces) #creates matrix with time and space dimensions
  for(m in 1:TimeLength){
    SolarGainWallsWatts[m, 1:NoOfSurfaces] = as.matrix((SolarIrradiation[m,1:NoOfSurfaces])*(EffectiveSolarAreaOpaq) - FormFactor[1,1]*ThermalRadiation) #calculates monthly solar gain for walls in Watts
  }
  
  SolarGainWalls = t(SolarGainWallsWatts)%*%diag(TimeStep) # in MJ
  
  #for horizontal surfaces (roof):
  ESAOpaqRoof = Rext*Alpha*Uroof*Aroof #calculates effective solar collection area for opaque surfaces (roof)
  
  ThermRadRoof = deltaT*Rext*5*Eo*Uroof*Aroof #calculates thermal radiation to the sky from roof
  
  if(DwellingPosition == 4 || DwellingPosition == 5){
    SolarGainRoof = 0
  }else{
    SolarGainRoof = (SolarIrradiation[1:TimeLength,9]*ESAOpaqRoof - FormFactor[1,2]*ThermRadRoof)%*%diag(TimeStep) #calculates monthly solar gain for roof in MJ
  }
  
  TotalOpaqueGain = (sum(SolarGainWalls)+SolarGainRoof) #calculates total solar gain for opaque surfaces in MJ per month
  
  Qsol = TotalOpaqueGain + TotalWindowGain #calculates total solar gains for each month in MJ
  
  sum(Qsol)
  
  # daylighting correction factor (SAP 2012, Appendix L)
  Zl = 0.83 #light access factor (SAP 2012, table 6d, Average overshading)
  Gl = 0.9*(1-FrameFactor)*Zl*(ST1*sum(Ag1) + ST2*sum(Ag2))/FloorArea # weighted ratio of glass area to floor area, eq. L5
  
  if(Gl <= 0.095){
    C2 = 52.2*Gl^2 - 9.94*Gl + 1.433 # daylight correction factor equation L3 & L4
  }else{
    C2 = 0.96
  }
  
  return(c(Qsol, C2))
}

# subFN: DHWLoad ####################################
# calculates domestic hot water consumption and internal gains due to DHW (see SAP 2009, BRE)
# outputs monthly values and yearly total in MJ
occupants=input_occupancy@Number
DaysperMonth=input_Constants@Time[,3]
cylinderInsulation=input_hvac@TankInsulation
kWhMJ=input_Constants@kWhMJ

DHWLoad <- function(occupants, DaysperMonth, cylinderInsulation, kWhMJ ){
    #BASED ON SAP 2012 (Table 1b, Table 2,2b,3a)
    
    Vd_av = rnorm(1,(25*occupants + 36),3) #annual average hot water volume (litres/day), based on occupancy
    
    Fm = t(c(1.1, 1.06, 1.02, 0.98, 0.94, 0.9, 0.9, 0.94, 0.98, 1.02, 1.06, 1.1)) #monthly factor (Table 1c)
    deltaT = t(c(41.2, 41.4, 40.1, 37.6, 36.4, 33.9, 30.4, 33.4, 33.5, 36.3, 39.4, 39.9)) #temperature rise for hot water in K (for each month) (table 1d)
    Vd_m = Vd_av*Fm/1000 #monthly average hot water volume (m^3/day)
    
    Qdhw = 4.182*Vd_m*DaysperMonth*deltaT # domestic hot water demand in MJ/month (table 1b)
    #deltaT = temperature rise; 4.182 = specific heat capacity of water (kJ/kgK)
    
    #calculate distribution losses assuming factory insulated if insulated.
    if(cylinderInsulation == 0){
      Qdist = 0 # no distribution losses (i.e. instantaneous water heating)
      Qcombi = (600*kWhMJ/365)*DaysperMonth # monthly loss for combi boilers (MJ/month)
      Qloss = 0 # no storage losses
    } # if no hot water tank (i.e. no water storage)
    else{
      Vol = runif(1,90,130) #storage cylinder volume in litres
      Qdist = 0.15*Qdhw #distribution losses = 0.15 x hot water demand
      L = 0.005 + 0.55/(cylinderInsulation + 4.0) # cylinder loss factor (SAP 2012, table 2) (kWh/litre/day)
      Qloss = L*0.6*DaysperMonth*kWhMJ*Vol #multiplied by temperature factor (table 2b), days per month, and cylinder volume
      # water storage loss in MJ/month
      Qcombi = 0;
    }
    
    Qgain = 0.25*(0.85*Qdhw + Qcombi) + 0.8*(Qdist + Qloss) #heat gains from water heating (MJ/month)
    
    Qdhw = 0.85*Qdhw + Qdist + Qloss + Qcombi #total heat required for water heating (MJ/month)
    
    return(c(Qdhw, Qgain))
  }

# subFN: LightingLoad ###############################
# calculates power consumption and internal gains due to lighting (BASED ON SAP 2012, APPENDIX L1)
# outputs monthly values and yearly total in MJ

LightingLoad <- function(PI, LEL, LELFactor, LCF, FloorArea, Occupancy, C2, SunsetTime, TimeStep, kWhMJ){
  
  #Calculates energy consumption due to lighting
  #   Provides internal gains from lighting, based on power intensity of
  #   lights, percentage of low-energy lighting, light-control factor, and
  #   occupancy
  
  #BASED ON SAP 2009, APPENDIX L1
  
  C1 = 1-0.5*LEL #correction factor based on fraction of low energy lighting
  
  Ea = rnorm(1,(59.73*(FloorArea*Occupancy)^0.4714),50) #annual energy use in kWh/year based on floor area and occupancy without low-energy lighting (L1)
  
  Ea = Ea*C1*C2 #corrected for daylighting and low energy lighting
  
  Qlights = rep(0,12)
  
  for(m in 1:12){
    Qlights[m] = Ea*(1+0.5*cos(2*pi*(m-0.2)/12))*TimeStep[m]/365 #in kWh/month
  }

  
  Qlights = Qlights*kWhMJ # in MJ/month
  
  return(Qlights)
}

# subFN: OccupantLoad ###############################
# calculates internal gains due to occupants (see SAP 2012, Table 5)
# outputs monthly values and yearly total in MJ

OccupantLoad <- function(NumberPeople, OccupantGain, TimeStep){
#   Calculates internal gains due to occupants
#   Based on number of occupants x gain per person x seconds per month
  
Qocc = NumberPeople*OccupantGain%*%TimeStep; #occupant gain in MJ per month
  
#if NumberPeople <3 %for smaller households
#Qocc = NumberPeople*OccupantGain*TimeStep; %occupant gain in MJ per month (assumes 2 adults)
#elseif NumberPeople >=3
#Qocc = 2*OccupantGain*TimeStep + (NumberPeople-2)*(OccupantGain*0.5)*TimeStep; %occupant gain in MJ per month (assumes 2 adults and children/elderly)
#end
  
return(Qocc)
}
  
# subFN: ApplianceLoad ##############################
# calculates power consumption and internal gains due to appliances (based on SAP 2009, Appendix L2)
# outputs monthly values and yearly total in MJ

ApplianceLoad <- function(FloorArea, Occupancy, TimeStep, kWhMJ){
  #   Calculates appliances loads

  # based on SAP 2009 (Appendix L2)
  Ea = rnorm(1,(207.8*(FloorArea*Occupancy)^0.4714),100) #annual energy use in kWh/year based on floor area and occupancy
  
  Qapp = rep(0,12)
  
  for(m=1:12){
    Qapp[m] = Ea*(1+0.157*cos(2*pi*(m-1.78)/12))*TimeStep(m)/365 #in kWh/month
  }
  
  Qapp = Qapp*kWhMJ #in MJ/month

  return(sum(Qapp))  # Yearly appliances load in MJ
  }
  
# subFN: InternalGains ##############################
# calculates internal gains in MJ/month (based on SAP 2009, table 5)
# estimate based on: lighting loads, appliance loads, occupants, floor area, and fraction of the space/time occupied
 
InternalGains <- function(Lights, Appliances, Occupants, DHW, occupancy, TimeSteps){
#Calculates internal gains based on lighting, appliances, occupants,
#fraction of the space / time that is occupied, and total floor area
  
#Monthly internal gains in MJ
  
#based on SAP 2009, table 5
Cooking = rnorm(1,(35 + 7*occupancy),5)*TimeSteps #internal gains from cooking (MJ/month)
Losses = rnorm(1,(40*occupancy),3)*TimeSteps #losses due to heating of incoming cold water and evaporation)
  
Qint = 0.85*Lights + Appliances + Occupants + DHW + Cooking - Losses;
  
return(Qint)
  
}
  
# subFN: UtilisationFactors #########################
# calculates the gain utilisation factor and the loss utilisation factor

UtilisationFactors <- function(GainRatio, LossRatio, ThermalMass, TotalArea, Ht, Hv){
  # Calculates Gain Utilisation Factor and Loss Utilisation Factor (see EN 13790)
  # Based heat gain/loss ratio, thermal mass, floor area, and heat transfer
  # coefficients (for conduction and convection
                    
  TimeLength = length(GainRatio) #creates variable with dimensions equal to the number of time-steps (e.g. 12 months in a year)
                    
  HeatCapacity = ThermalMass*TotalArea #calculates heat capacity of dwelling in J/K
  HtTotal = sum(Ht) #calculates total conduction transfer coefficient
                    
  #for heating period:
                      
  thetaH = (HeatCapacity/3600)/(HtTotal+Hv(1,1)) # thetaH = Cm/3600/h
  alphaH = 1 + thetaH/15 
                    
  UFgain = rep(0,TimeLength)
  
  for(m = 1:TimeLength){
    if(GainRatio[m]>0){
      UFgain[m] = (1-GainRatio[m]^alphaH)/(1-GainRatio[m]^(alphaH+1))
    }
    else{
      UFgain(m,1) = 1/GainRatio(m,1)
    }
  }

  #for cooling period:
                      
  thetaC = (HeatCapacity/3600)/(HtTotal+Hv(1,2))
  alphaC = 1 + thetaC/15
  
  UFloss = zeros(TimeLength,1)
                    
  for(m = 1:TimeLength){
    if(LossRatio(m,1)>0){
      UFloss[M] = (1-LossRatio[m]^alphaC)/(1-LossRatio[m]^(alphaC+1))
    }
    else{
      UFloss[m] = 1/LossRatio[m]
    }
  }
                    
  return(UFgain, UFloss)

}
