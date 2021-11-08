# SUSDEM_Cls.R
# Source script for SUSDEM Input Classes and Associated Fns.
# Adapted from Booth & Choudhary (2013) MATLAB version.

# CLASS: CONSTANT ###############################
setClass("Constants", 
         representation(Time = "matrix", YearTime = "matrix", kWhMJ="numeric"),
         prototype(Time = rbind(c(2.6784, 744, 31),
                                c(2.4192, 672, 28),
                                c(2.6784, 744, 31),
                                c(2.592, 720, 30),
                                c(2.6784, 744, 31),
                                c(2.592, 720, 30),
                                c(2.6784,	744, 31),
                                c(2.6784, 744, 31),
                                c(2.592, 720, 30),
                                c(2.6784, 744, 31),
                                c(2.592, 720, 30),
                                c(2.6784, 744, 31)),
                   YearTime = rbind(c(31.536,8760,365)),
                   kWhMJ = 3.6))
#kWh to MJ
# Constant values used for calculations
# Days, hours, and seconds in a month 
# Time = [Ms, hours, days] per month

# CLASS: COEFFICIENTS ###############################
setClass("Coefficients",
         representation(Eo = "numeric",
                        Et = "numeric",
                        FormFactor = "matrix",
                        Alpha = "numeric",
                        R = "numeric",
                        deltaT = "numeric",
                        FrameFactor = "numeric",
                        HeatCapacity = "numeric",
                        AirStandards = "numeric",
                        DoorSize = "numeric",
                        PI = "numeric"),
         prototype(Eo = 0.88, #opaque emissivity
                   Et = 0.84, #transparent emissivity
                   FormFactor = rbind(c(0.5,1)), #Form factor for surfaces [vertical,horizontal]
                   Alpha = 0.9, #dimensionless absortion coefficient for solar radiaion of the opaque part
                   R = 0.05, #external surface heat resistance of the element
                   deltaT = 13, #the average difference between the external air temperature and the apparent sky temperature, in °C
                   FrameFactor = 0.25, #Frame factor
                   HeatCapacity = 1.2, #Heat capacity of air = density x specific heat capacity (kJ/litreK)
                   AirStandards = 8, #minimum air flow for decent air quality (l/s)
                   DoorSize = 1.85, #area of a door in m^2
                   PI = 7.5 #installed power intensity in W/m^2/(100lux)
         ))

# list of coefficients
# Constants that must be set before running program, such as
# emissivity, form factor, absorption, etc.

# CLASS: GEOMETRY ###############################
setClass("Geometry",
         representation(Storeys = "numeric", #Number of storeys
                        Heights = "numeric",#row vector - Height in m of each storey (floor)
                        TotalArea = "numeric",#Total floor area of dwelling in m^2
                        Volume = "numeric",#Total volume of dwelling in m^3
                        GroundArea = "numeric",#Floor area of ground floor in m^2
                        GroundPerimeter = "numeric",#Floor perimeter of ground floor in m^2
                        RoofArea = "numeric",#Area of ceiling/roof in m^2
                        FacadeArea = "numeric",#Total facade area of all faces in m^2 (including internal and external walls)
                        EnvelopeArea = "numeric"#Total envelope area = facade area + floor area + roof area
         ))

# In R we need to define a function seperately.
geometry <- function(storeys,areas,heights,perimeters){
  geometry <- new("Geometry")
  geometry@Storeys = storeys
  geometry@Heights = heights
  geometry@TotalArea = sum(areas) #Total floor area is addition of floor areas for each floor
  geometry@Volume = as.numeric(heights%*%areas)
  geometry@GroundArea = areas[1]
  geometry@GroundPerimeter = perimeters[1]
  geometry@RoofArea = areas[storeys]
  geometry@FacadeArea = as.numeric(heights%*%(perimeters))
  geometry@EnvelopeArea = geometry@FacadeArea + geometry@RoofArea + geometry@GroundArea
  return(geometry)
}


# CLASS: ENVELOPE ###############################

setClass("Envelope",
         representation(ExternalSurfaces = "matrix", #Row vector of length 8, specifing surfaces from SW to W
                        # Either 1=TRUE (external surface) or 0=FALSE (internal surface or no surface)
                        InternalSurfaces = "matrix",#Row vector of length 8, specifing surfaces from SW to W
                        #Either 1=TRUE (internal surface) or 0=FALSE (external surface or no surface)
                        ShadingFactors = "matrix", #Row vector of length 8, specifing shading of surfaces from SW to W
                        #ShadingFactor is from 0 (no sunlight) to 1 (maximum sunlight)
                        #should be 0 for orientations that are internal surfaces
                        Walls = "matrix", #Area in m^2 of walls for each orientation from SW to W
                        Glazing1 = "matrix", #Area in m^2 of single glazing for each orientation from SW to W
                        Glazing2 = "matrix", #Area in m^2 of double glazing for each orientation from SW to W
                        Doors = "numeric",
                        #Area in m^2 of second glazing type for each orientation from SW to W
                        TotalAreas = "matrix" #Total surface area for each orientation
                        #Should be addition of all the above areas
         ))


envelope <- function(FacadeArea, DwellingPosition, Orientation, WWR, PercentageDoubleGlazed, DoorSize, GlazedArea){
  require(pracma)
  # FacadeArea = Total facade area of all faces in m^2 (including internal and external walls)
  # DwellingPosition = dwelling position (mid-terrace,end-terrace,semi-detached; ground, mid, top floor,etc.)
  # Orientation = dwelling orientation [N,NE,E,SE,S,SW,W,NW]
  # WWR = window-to-wall ratio
  # PercentageDoubleGlazes = percentage of glazing that is double glazing
  # Door size, m^2
  # GlazedArea = area of glazing (m^2)
  
  envelope = new("Envelope")
  
  # sets external/internal surfaces dependent on dwelling position
  # eight vertical surface orientations [N,NE,E,SE,S,SW,W,NW]
  if(DwellingPosition == 4 || DwellingPosition == 5 || DwellingPosition == 6){
    envelope@ExternalSurfaces = rbind(c(1,0,1,0,0,0,0,0)) # two external vertical surfaces
    envelope@InternalSurfaces = rbind(c(0,0,0,0,1,0,1,0))
    Entrances = rbind(c(1,0,0,0,0,0,0,0)) # assumes front door only
  } # if dwelling is a flat or maisonette
  else if(DwellingPosition == 0){ # if dwelling is detached
    envelope@ExternalSurfaces = rbind(c(1,0,1,0,1,0,1,0)) # four external vertical surfaces
    envelope@InternalSurfaces = rbind(c(0,0,0,0,0,0,0,0))
    Entrances = rbind(c(1,0,0,0,1,0,0,0)) # assumes front door and back doors
  }
  else if(DwellingPosition == 1 || DwellingPosition == 3){ # if dwelling is semi-detached or end-terrace
    envelope@ExternalSurfaces = rbind(c(1,0,1,0,1,0,0,0)) # three external vertical surfaces
    envelope@InternalSurfaces = rbind(c(0,0,0,0,0,0,1,0))
    Entrances = rbind(c(1,0,0,0,1,0,0,0)) # assumes front door and back doors
  }
  else if(DwellingPosition == 2){ # if dwelling is mid-terrace
    envelope@ExternalSurfaces = rbind(c(1,0,0,0,1,0,0,0)) # two external vertical surfaces
    envelope@InternalSurfaces = rbind(c(0,0,1,0,0,0,1,0))
    Entrances = rbind(c(1,0,0,0,1,0,0,0)) # assumes front door and back doors
  }
  
  envelope@ExternalSurfaces = rbind(circshift(envelope@ExternalSurfaces, c(0,Orientation-1)))
  envelope@InternalSurfaces = rbind(circshift(envelope@InternalSurfaces, c(0,Orientation-1)))
  Entrances = rbind(circshift(Entrances, c(0,Orientation-1)))
  
  envelope@ShadingFactors = envelope@ExternalSurfaces # shading factors assumed to be equal to external surfaces
  
  envelope@TotalAreas = (FacadeArea/4)*(envelope@ExternalSurfaces+envelope@InternalSurfaces) #assumes cuboid with four vertical surfaces; equally distributes facade area amoungst vertical surfaces
  
  #GlazingAreas = envelope.ExternalSurfaces*GlazedArea/(sum(envelope.ExternalSurfaces)); % distributes total glazing area equally over the external vertical surfaces
  GlazingAreas = envelope@ExternalSurfaces*(FacadeArea/4)*WWR # total window area = total external surface area x window-to-wall ratio
  envelope@Glazing1 = GlazingAreas*(1-PercentageDoubleGlazed/100) # areas for two-window types based on %double glazing
  envelope@Glazing2 = GlazingAreas*(PercentageDoubleGlazed/100)
  
  envelope@Doors = Entrances*DoorSize #door size assumed to be constant specified in "coefficients" file
  
  envelope@Walls = envelope@TotalAreas - envelope@Doors - GlazingAreas # wall areas = total surface areas - window areas - door areas
  
  return(envelope)
}

# CLASS: CONSTRUCTION ###########################

setClass("Constructions",
         representation(ExternalWall = "numeric", # Calculates U-value external wall (W/m2K)
                        InternalWall = "numeric", # Calculates U-value external wall (W/m2K)
                        Roof = "numeric", # Calculates U-value of ceiling or roof (W/m2K)
                        Floor = "numeric", # Calculates U-value of floor (W/m2K)
                        Glazing1 = "numeric", # Calculates U-value of first glazing (W/m2K)
                        SolarT1 = "numeric", # Calculates solar transmittance of first glazing
                        Glazing2 = "numeric", # Calculates U-value of second glazing (W/m2K)
                        SolarT2 = "numeric", # Calculates solar transmittance of second glazing
                        Door = "numeric", # Calculates U-value of door (W/m2K)
                        ShadingDevice = "numeric", #Shading factor dependent on control type
                        ThermalMass = "numeric" #Calulates thermal mass of dwelling (J/m2K))
         ))

constructions <- function(EW1,EW2,DA,IW,SG,DG,roof,floor,door,SD,TM,DwellingType,DwellingPosition,GroundArea,GroundPerimeter){
  #EW1 = wall construction type
  #EW2 = wall insulation type
  #DA = dwelling age
  #IW = internal wall
  #SG = single glazing U-value (W/m^2K)
  #DG = double glazing U-value (W/m^2K)
  #TM = thermal mass (J/K.m^2)
  #DwellingType = structural type (flat, house, etc.)
  #DwellingPosition = (mid-terrace,end-terrace,semi-detached; ground, mid, top floor,etc.)
  #GroundArea = dwelling footprint (m^2)
  #GroundPerimeter = ground floor perimeter (m)
  constructions = new("Constructions")
  
  #see SAP 2009 for assumptions
  if(EW1 == 1 && (EW2 == 0 || EW2 == 1 || EW2 == 4)){# 1 is uninsulated single brick
    constructions@ExternalWall = rnorm(1,1.2,0.175) #U-value in W/m2K
    constructions@ThermalMass = 250000; # heavy level thermal mass (J/m^2K)
    w = 0.22; # total wall thickness (for floor calculation below)
  } 
  else if(EW1 == 1 && (EW2 == 2 || EW2 == 3)){# 1 is insulated single brick
    constructions@ExternalWall = rnorm(1,0.45,0.05) #U-value in W/m2K
    constructions@ThermalMass = 250000 # heavy level thermal mass (J/m^2K)
    w = 0.29
  } 
  else if(EW1 == 0 && (EW2 == 0 || EW2 == 1)){ # a cavity wall with unknown or as built insulation
    constructions@ExternalWall = rnorm(1,1.1,0.11)
    constructions@ThermalMass = 250000; # very heavy level thermal mass (J/m^2K)
    w = 0.25;
  }
  else if(EW1 == 0 && (EW2 == 2 || EW2 == 3)){ # a cavity wall with external or filled insulation
    constructions@ExternalWall = rnorm(1,0.4,0.05);
    constructions@ThermalMass = 250000; # very heavy level thermal mass (J/m^2K)
    w = 0.25;
  } 
  else if(EW1 == 2 && (EW2 == 0 || EW2 == 1)){# system built with unknown or as built insulation
    constructions@ExternalWall = rnorm(1,1.0,0.1);
    constructions@ThermalMass = 165000; # medium level thermal mass (J/m^2K)
    w = 0.32;
  } 
  else if(EW1 == 2 && (EW2 == 2 || EW2 == 3)){ # 2 is system built with external insulation
    constructions@ExternalWall = rnorm(1,0.45,0.05);
    constructions@ThermalMass = 165000; # medium level thermal mass (J/m^2K)
    w = 0.25;
  } 
  else if(EW1 == 3){ # 3 is timber frame
    constructions@ExternalWall = rnorm(1,0.4,0.075);
    constructions@ThermalMass = 110000; # very light level thermal mass (J/m^2K)
    w = 0.15;
  } 
  
  
  #internal wall
  constructions@InternalWall = IW; # uniformly random U-value in W/m^2K between 1.5 and 2.0
  
  #roof
  if((DwellingType==1 || DwellingType==3) && ( DwellingPosition == 4 || DwellingPosition == 5)){ # a flat/maisonette on ground/mid-floor
    constructions@Roof = 2.3
  }# a concrete or timber ceiling with U-value in W/m2K
  else if((DwellingType==1 || DwellingType==3) && ( DwellingPosition == 6)){# a flat/maisonette on top floor with unknown insulation
    if(roof == 0){
      roof = 179; # assume insulation of average thickness (mm)
      constructions@Roof = (1/(0.435 + roof*0.021)); # calculates based on roof insulation thickness in mm    
    }
    else{
      constructions@Roof = (1/(0.435 + roof*0.021));
    }
  } 
  else{
    constructions@Roof = (1/(0.435 + roof*0.021)); # calculates based on roof insulation thickness in mm
  }
  
  #ground floor
  #BASED ON EN-ISO standard 13370 2007            
  if((DwellingType==0 || DwellingType==2) || ( DwellingPosition == 4)){# if dwelling is a house or bungalow or a ground floor flat
    lambda = 1.5; #ground conductivity (W/m2K)
    B = GroundArea/(0.5*GroundPerimeter); # characteristic dimension of the floor
    if(floor==1){ # 1 is a solid floor slab
      d = w + lambda*(0.71+0.04+0.17); # equivalent thickness = wall thickness + ground conductivity x (floor resistance + outer surface resistance + inner surface resistance)
      constructions@Floor = (2*lambda/(pi*B+d))*log((pi*B/d)+1); #U-value in W/m2K
    } 
    else if(floor==2){ # 2 is a suspended timber floor
      Uf = 1.2; #floor U-value in W/m2K
      d = w + lambda*(0.71+0.04+0.17);
      Ug = (2*lambda/(pi*B+d))*log((pi*B/d)+1); #ground U-value in W/m2K
      constructions@Floor = 1/((1/Uf)+(1/Ug));
    } 
    else if(floor==3){ # is a suspended non-timber floor
      Uf = 1.2; #floor U-value in W/m2K
      d = w + lambda*(0.71+0.04+0.17);
      Ug = (2*lambda/(pi*B+d))*log((pi*B/d)+1); #ground U-value in W/m2K
      constructions@Floor = 1/((1/Uf)+(1/Ug));
    } 
    else if(floor==4){ # is an insulated floor
      d = w + lambda*(3.25+0.04+0.17); # equivalent thickness = wall thickness + ground conductivity x (floor resistance + outer surface resistance + inner surface resistance)
      constructions@Floor = lambda/(0.457*B+d); #U-value in W/m2K
    } 
    else{
      constructions@Floor = runif(1,0.2,0.3); # uniform random U-value in W/m2K between 0.2 and 0.3 
    }
  }
  else{ # unknown floor construction or not ground floor
    constructions@Floor = runif(1,0.2,0.3); # uniform random U-value in W/m2K between 0.2 and 0.3
  }
  
  
  #single-glazing
  constructions@Glazing1 = SG; #U-value in W/m2K
  constructions@SolarT1 = 0.85; #Solar Transmittance
  
  #double-glazing
  constructions@Glazing2 = DG;
  constructions@SolarT2 = 0.76;
  
  #door
  constructions@Door = door;
  
  if(SD==1){ #user controlled
    constructions@ShadingDevice = c(0.5,0.5); #reduction factors in [heating season, cooling season]
  } 
  else if(SD==2){ #automatic control
    constructions@ShadingDevice = c(0.5,0.35);
  } 
  else{ #all other cases
    constructions@ShadingDevice = c(1,1);
  }
  
  
  #adjust U-values for building age
  if(DA < 3){#if building is pre-war
    constructions@ExternalWall = constructions@ExternalWall*1.4; #increase U-value due to old age
    constructions@Floor = constructions@Floor*1.4; #increase U-value due to old age
    constructions@Roof = constructions@Roof*1.4; #increase U-value due to old age
    constructions@Glazing1 = constructions@Glazing1*1.4; #increase U-value due to old age
    constructions@Glazing2 = constructions@Glazing2*1.4; #increase U-value due to old age
  } 
  else if(3 >= DA && DA < 5){#if building is post-war but pre-1980
    #keep U-values as specified
  } 
  else if(DA >=5){ #if building is post-1980
    constructions@ExternalWall = constructions@ExternalWall*0.6; #decrease U-value due to new age
    constructions@Floor = constructions@Floor*0.6; #decrease U-value due to new age
    constructions@Roof = constructions@Roof*0.6; #decrease U-value due to new age
    constructions@Glazing1 = constructions@Glazing1*0.6; #decrease U-value due to new age
    constructions@Glazing2 = constructions@Glazing2*0.6; #decrease U-value due to new age  
  }
  
  return(constructions)
}

# CLASS: HVAC ###################################

setClass("HVAC",
         representation(Infiltration = "numeric", #air leakage in l/s/m2
                        NatVent = "numeric", #natural ventilation for cooling in l/s/m2
                        EER = "numeric", #Energy Efficiency Ratio for cooling
                        COP = "numeric", #Coefficient of Performance for heating
                        PumpCool = "numeric", #Pump control weighting factor for heating
                        PumpHeat = "numeric", #Pump control weighting factor for cooling
                        DHWEfficiency = "numeric", #Energy Efficiency of DHW system
                        FractionHeated = "numeric", #Fraction of space heated
                        TankInsulation = "numeric" #Insulation thickness of hot water storage tank
                        
         ))

hvac <- function(infil,natvent,eer,cop,boiler,heating1,heating2,waterheating,tankinsulation,PC,PH,DwellingPosition,fractionheated,DA){
  #infil = air leakage (l/s/m^2) @ 50Pa
  #natvent = natural ventilation rate (ACH)
  #eer = cooling supply efficiency
  #cop = heating coefficient of performance
  #boiler = boiler efficiency
  #heating1 = primary heating fuel
  #heating2 = secondary heating type
  #waterheating = DHW heating type
  #tankinsulation = hot tank cylinder insulation thickness (mm)
  #PC / PH = cooling / heating pump
  #DwellingPosition = (mid-terrace,end-terrace,semi-detached; ground, mid, top floor,etc.)
  #fractionheated = fraction of the space (& time) that is heated
  #DA = dwelling construction age
  
  hvac = new("HVAC")
  
  hvac@Infiltration = infil/20; #infil = air leakage (l/s/m^2) @ 50Pa
  # divide by 20 to obtained annual average at room pressure
  # see CIBSE GUIDE A (section 4.7.2.1) and SAP 2009 (section 2.3) for details
  
  if(DwellingPosition == 5){ # increase natural ventilation and infiltration with dwelling height
    hvac@NatVent = natvent*1.2;
    hvac@Infiltration = hvac@Infiltration*1.2;
  } 
  else if(DwellingPosition == 6){
    hvac@NatVent = natvent*1.4;
    hvac@Infiltration = hvac@Infiltration*1.4;
  }
  else{
    hvac@NatVent = natvent;    
  }
  
  # increase / decrease natural ventilation and infiltration with dwelling age
  if(DA < 3){ #if building is pre-war
    hvac@NatVent = natvent*1.25;
    hvac@Infiltration = hvac@Infiltration*1.25;
  } 
  else if(3 >= DA && DA < 5){ #if building is post-war but pre-1980
    #keep infiltration as specified
  } 
  else if(DA >=5){ #if building is post-1980
    hvac@NatVent = natvent*0.9;
    hvac@Infiltration = hvac@Infiltration*0.9;
  } 
  #Natural ventilation is in ACH
  
  hvac@EER = eer; # cooling supply efficiency
  
  if((heating1 == 1 || heating1 == 0) && (heating2 == 0 || heating2 == 1)){ #if heating is gas or smokeless fuel only
    hvac@COP = boiler; # heating coefficient of performance = boiler efficiency
  } 
  else if((heating1 == 1 || heating1 == 0) && (heating2 == 2)){ #if heating is gas or smokeless fuel plus electric
    hvac@COP = cop; # heating coefficient of performance is drawn randomly from posterior  
  } 
  else if((heating1 == 2 || heating1 == 3)){#if heating is electric (dual tariff or standard)
    hvac@COP = cop; # heating coefficient of performance is drawn randomly from posterior   
  } 
  
  hvac@FractionHeated = fractionheated; # fraction of the space (& time) that is heated
  
  
  #DHW efficiency (based on SAP 2009, 9.2.1 and table 4b)
  if(waterheating == 1 || waterheating == 3 || waterheating == 0 || waterheating == 4){ #if gas (combi-boiler),electric (standard), or smokeless fuel water heating
    hvac@DHWEfficiency = boiler-0.09; #summer seasonal efficiency is normal efficiency - 9#
  } 
  else if(waterheating == 2){ #if electric (dual tariff) water heating
    hvac@DHWEfficiency = boiler; #efficiency is same as space heating boiler efficiency
  } 
  
  if(PC == 1){
    hvac@PumpCool = 0;
  } #no pump for cooling
  else if(PC == 2){
    hvac@PumpCool = 0.5;
  } #automatic control more than 50#
  else{
    hvac@PumpCool = 1;
  } # all other cases
  
  if(PH == 1){
    hvac@PumpHeat = 0;
  } #no pump for heating
  else if(PH == 2){
    hvac@PumpHeat = 0.5;
  } #automatic control more than 50#
  else{
    hvac@PumpHeat = 1;
  } # all other cases
  
  
  hvac@TankInsulation = tankinsulation; #hot water tank insulation thickness in mm
  
  return(hvac)
}

# CLASS: APPLIANCES #############################

setClass("Appliances",
         representation(CapitaConsumption = "numeric", #Average energy consumption per occupant per day(kWh/day) for electrical appliances
                        HouseholdConsumption = "numeric",# %Average energy consumption per household per day(kWh/day) for electrical appliances
                        Loads = "matrix" #Average energy consumption per occupant per day(kWh/day), taken from Yao&Steemers(2005)
                        # Appliances are (from left to right) [Electric hob, Electric
                        # oven,Microwave oven, Refrigerator, Fridge-freezer, Freezer,
                        # Colour-television set, Video recorder, Clothes-washing machine,
                        # Tumble-drier, Dishwasher, Electric kettle, Iron, Vacuum cleaner, Personal Computer, Miscellaneous
         ),
         prototype(Loads = rbind(c(0.39, 0.22, 0.07, 0.33, 0.56, 0.55, 0.27, 0.09, 0.2, 0.28, 0.48, 0.28, 0.09, 0.04, 0.3, 0.33))))

appliances <- function(CapitaConsumption, HouseholdConsumption){
  appliances <- new("Appliances")
  
  appliances@CapitaConsumption = CapitaConsumption;
  appliances@HouseholdConsumption = HouseholdConsumption;
  
  return(appliances)
}

# CLASS: LIGHTS #################################

setClass("Lights",
         representation(PowerIntensity = "numeric", #Installed peak lighting power intensity in W/m^2/(100lux)
                        LEL = "numeric", #Low Energy Lighting percentage
                        LCF = "numeric", #lighting control factor
                        LELFactor = "numeric" #energy consumption of LEL as a fraction of normal lighting
         ))

lights <- function(IL,PI,lel,lcf,LELfactor){
  #IL = illuminance level (lux)
  #PI = power intensity in W/m^2/(100lux)
  #lel = percentage of lighting that is low-energy
  #lcf = lighting control factor
  #LELfactor = energy use reduction factor for low-energy lighting
  
  lights = new("Lights")
  
  lux = IL/100
  
  lights@PowerIntensity = PI*lux # PI = power intensity in W/m^2/(100lux)
  lights@LEL = lel/100 #turned from percentage into fraction
  lights@LELFactor = LELfactor
  
  if(lcf == 1){
    lights@LCF = 1
  } # manual control
  else{
    lights@LCF = 0.9
  }
  # automatic/sensor control
  
  return(lights)
}


# CLASS: OCCUPANTS ##############################

setClass("Occupants",
         representation(Number = "numeric", #Number of occupants
                        #OccupantGain = 100 #Gain per occupant in W/person
                        OccupantGain = "numeric" #Gain per occupant in W/person (from SAP 2009, Table 5)
                        # based on an averaged value
                        # (averaged across time and accounting for presence of children)
         ),
         prototype(Number = 60)
)

occupancy <- function(HouseholdNumber){
  # HouseholdNumber = number of household occupants
  occupancy <- new("Occupants")
  
  occupancy@Number = HouseholdNumber     
  
  return(occupancy)
}

# CLASS: WEATHER ################################

setClass("Weather",
         representation(ExternalTemp = "matrix", #Monthly average temperature in degrees C.
                        GroundTemp = "matrix", #Monthly average ground temperature
                        SolarIrr = "matrix", #Monthly average solar irradiation (W/m2)
                        SunsetTime = "matrix" #Hour of sunset
         )
)

weather <- function(ExTemp, solarIrr, sunset){
  
  weather <- new("Weather")
  
  weather@ExternalTemp = ExTemp;
  weather@GroundTemp = ExTemp; # temperature of the ground is same (on average) as external temperature - this is an assumption that needs to be altered
  weather@SolarIrr = solarIrr;
  weather@SunsetTime = sunset;
  
  return(weather)
}

# CLASS: SETPOINT ###############################

setClass("SetPoint",
         representation(
           THeating = "numeric", #Set-point temperature at which heating operates
           TCooling = "numeric", #Set-point temperature at which cooling operates
           Tpubspace = "numeric", # Temperature of public spaces
           Tground = "numeric" #Ground temperature
         ),
         prototype(Tground = 10)
)

SP <- function(TH,TC,Tps){
  
  SP <- new("SetPoint")
  
  SP@THeating = TH
  SP@TCooling = TC
  SP@Tpubspace = Tps
  
  return(SP)
}

