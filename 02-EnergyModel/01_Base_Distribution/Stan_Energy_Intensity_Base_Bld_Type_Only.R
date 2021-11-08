# Stan_Energy_Intensity_Base.R
# This runs a multilevel Bayesian regression model using publicly 
# available data to produce base energy intensity distributions for 
# Microsimulation model. 

# INPUTS
# This model takes as inputs:
# 1) MSOA energy intensity by property typology (NEED/BEIS)
# 2) EPC records for region of interest.

# OUTPUTS
# For each household typology j, a distribution which forms our prior 
# for Energy Intensity

# MODEL FORMULATION
# For a given household i, belonging to typology j, mean total energy use
# is related to floor area x as follows:
#
# Ei ~ N(Ei[j]x, sigma)
# 
# sigma - precision
# 
# Ei[j] ~ N(mu_E, sigma_E)
# 

require(dplyr)

# NEED DATA PROCESSING #####
# Pre-processing the NEED 50,000 household sample to breakdown Energy Intensity by
# Region, and Age-Building Type Category

# Load data from NEED csv

NEED_data <- read.csv(url("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/857035/anon_set_50k_2019.csv"), header=T, stringsAsFactors = F)

# Assign group numbers based on Building Type and Age
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
}

household_typology <- function(need_df){
  need_df$group<-NULL
  need_df$group<-as.vector((mapply(typology_parser, x=need_df$PROP_TYPE, y=need_df$PROP_AGE_FINAL)))
  return(need_df)
}

NEED_data_typecast <- household_typology(NEED_data)

# Approximate area based on area banding
area_approximator <- function(area_df){
  if(area_df == 1){
    area_spec <- 40
  }
  else if(area_df == 2){
    area_spec <- 75
  }
  else if(area_df == 3){
    area_spec <- 125
  }
  else if(area_df == 4){
    area_spec <- 175
  }
  else if(area_df == 5){
    area_spec <- 225
  }
}

NEED_data_typecast$floor_area <- as.vector(unlist(lapply(NEED_data_typecast$FLOOR_AREA_BAND, area_approximator)))
NEED_data_typecast <- NEED_data_typecast %>% filter(!is.na(Econs2017)) %>% mutate(E_INT=Econs2017/floor_area)
NEED_data_typecast <- NEED_data_typecast %>% filter(!is.na(Gcons2017)) %>% mutate(G_INT=Gcons2017/floor_area)
NEED_data_typecast$E_TOT <- NEED_data_typecast$E_INT + NEED_data_typecast$G_INT

# Visualization check 
require(ggplot2)

#ggplot(NEED_data_typecast) + geom_density(aes(x=E_INT), fill = "#C7DED2") + facet_grid(PROP_TYPE ~ PROP_AGE_FINAL) + xlim(0,80) + xlab("Electricity Energy Intensity kWh/m^2/year")+theme_minimal()

#ggplot(NEED_data_typecast) + geom_density(aes(x=E_INT+G_INT, group=IMD_band, colour=IMD_band)) + facet_grid(PROP_TYPE ~ PROP_AGE_FINAL) + xlim(0,300) + xlab("Gas Energy Intensity kWh/m^2/year")+ theme_minimal()

#ggplot(NEED_data_typecast) + geom_col(aes(y=mean(E_INT+G_INT), x=IMD_band, colour=IMD_band)) + facet_grid(PROP_TYPE ~ PROP_AGE_FINAL) + xlim(0,6) + xlab("Gas Energy Intensity kWh/m^2/year")+ theme_minimal()

NEED_INEQ <- NEED_data_typecast %>% group_by(PROP_TYPE,PROP_AGE_FINAL,IMD_band) %>% summarise(E = mean(E_INT+G_INT)) 

#ggplot(NEED_INEQ) + geom_col(aes(y=E, x=IMD_band, fill=IMD_band)) +
#  facet_grid(PROP_TYPE ~ PROP_AGE_FINAL, scales = "free_y") + xlim(0,6) + xlab("IMD from 1 (most deprived) to 5 (least deprived)")+ theme_minimal()

# EPC DATA PROCESSING #####
# Fetch and process EPC certificates for a given area.

source("EPC_Search_Fn.R")

set.seed(2019)

library(rstan)
library(bayesplot)

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
Sys.setenv(LOCAL_CPPFLAGS = '-march=corei7 -mtune=corei7')

# LOAD ENV Vars #
samples_mcmc <- 1000

if(samples_mcmc > 4000){
  warmup_mcmc <- 1000
} else {
  warmup_mcmc <- (samples_mcmc*0.25)
}

chains_mcmc <- 2


  epc_df <- EPC_Search("E09000014")
  
  # Need to match age bands (approximately)
  
  epc_df_cl <- filter(epc_df, `construction-age-band` != "")
  epc_df_cl <- filter(epc_df_cl, `construction-age-band` != "NO DATA!")
  epc_df_cl <- filter(epc_df_cl, `construction-age-band` != "INVALID!")
  
  epc_age_band_convert <- function(epc_age){
    if(epc_age == "2018"){
      NEED_AGE_BANDS <- 104
    }
    else if(epc_age == "2020"){
      NEED_AGE_BANDS <- 104
    }
    else if(epc_age == "2019"){
      NEED_AGE_BANDS <- 104
    }
    else if(epc_age == "2021"){
      NEED_AGE_BANDS <- 104
    }
    else if(epc_age == "England and Wales: 2003-2006"){
      NEED_AGE_BANDS <- 104
    }
    else if(epc_age == "England and Wales: 2007-2011"){
      NEED_AGE_BANDS <- 104
    }
    else if(epc_age == "England and Wales: 2012 onwards"){
      NEED_AGE_BANDS <- 104
    }
    else if(epc_age == "England and Wales: 2007 onwards"){
      NEED_AGE_BANDS <- 104
    }
    else if(epc_age == "England and Wales: before 1900"){
      NEED_AGE_BANDS <- 101
    }
    else if(epc_age == "England and Wales: 1900-1929"){
      NEED_AGE_BANDS <- 101
    }
    else if(epc_age == "England and Wales: 1930-1949"){
      NEED_AGE_BANDS <- 102
    }
    else if(epc_age == "England and Wales: 1950-1966"){
      NEED_AGE_BANDS <- 102
    }
    else if(epc_age == "England and Wales: 1967-1975"){
      NEED_AGE_BANDS <- 102
    }
    else if(epc_age == "England and Wales: 1976-1982"){
      NEED_AGE_BANDS <- 103
    }
    else if(epc_age == "England and Wales: 1983-1990"){
      NEED_AGE_BANDS <- 103
    }
    else if(epc_age == "England and Wales: 1991-1995"){
      NEED_AGE_BANDS <- 103
    }
    else if(epc_age == "England and Wales: 1996-2002"){
      NEED_AGE_BANDS <- 103
    }else{
      NEED_AGE_BANDS <- NA
    }
  }
  
  #epc_df_cl$NEED_AGE_BANDS <- as.vector(unlist(lapply(epc_df_cl$`construction-age-band`, epc_age_band_convert)))
  
  epc_built_type_convert <- function(epc_type, epc_form){
    if(epc_type=="Bungalow" && epc_form != ""){
      built_type = "Bungalow"
    }
    else if(epc_type=="Flat" && epc_form != ""){
      built_type = "Flat"
    }
    else if(epc_type=="House" && epc_form == "Detached"){
      built_type = "Detatched"
    }
    else if(epc_type=="Maisonette" && epc_form == "Detached"){
      built_type = "Detatched"
    }
    else if(epc_type=="House" && epc_form == "Enclosed End-Terrace"){
      built_type = "End terrace"
    }
    else if(epc_type=="Maisonette" && epc_form == "Enclosed End-Terrace"){
      built_type = "End terrace"
    }
    else if(epc_type=="House" && epc_form == "End-Terrace"){
      built_type = "End terrace"
    }
    else if(epc_type=="Maisonette" && epc_form == "End-Terrace"){
      built_type = "End terrace"
    }
    else if(epc_type=="House" && epc_form == "Enclosed Mid-Terrace"){
      built_type = "Mid terrace"
    }
    else if(epc_type=="Maisonette" && epc_form == "Enclosed Mid-Terrace"){
      built_type = "Mid terrace"
    }
    else if(epc_type=="House" && epc_form == "Mid-Terrace"){
      built_type = "Mid terrace"
    }
    else if(epc_type=="Maisonette" && epc_form == "Mid-Terrace"){
      built_type = "Mid terrace"
    }
    else if(epc_type=="House" && epc_form == "Semi-Detached"){
      built_type = "Semi detached"
    }
    else if(epc_type=="Maisonette" && epc_form == "Semi-Detached"){
      built_type = "Semi detached"
    }else{
      built_type <- NA
    }
  }
  
  epc_df_cl$NEED_TYPE <- as.vector(unlist(mapply(epc_built_type_convert, epc_type=epc_df_cl$`property-type`,  epc_form = epc_df_cl$`built-form`)))
  
  epc_df_cl <- filter(epc_df_cl,!is.na(`NEED_TYPE`))
  #epc_df_cl <- filter(epc_df_cl,!is.na(`NEED_AGE_BANDS`))
  
  #epc_df_cl$group <- as.vector((mapply(typology_parser, x=epc_df_cl$NEED_TYPE, y=epc_df_cl$NEED_AGE_BANDS)))
  
  #epc_df_cl$E_INT <- as.numeric(epc_df_cl$`energy-consumption-current`)/as.numeric(epc_df_cl$`total-floor-area`)
  
NEED_data_typecast$type_group <-NULL
NEED_data_typecast$type_group[NEED_data_typecast$PROP_TYPE == "Bungalow"] <- 1
NEED_data_typecast$type_group[NEED_data_typecast$PROP_TYPE == "Detatched"] <- 2
NEED_data_typecast$type_group[NEED_data_typecast$PROP_TYPE == "End terrace"] <- 3
NEED_data_typecast$type_group[NEED_data_typecast$PROP_TYPE == "Flat"] <- 4
NEED_data_typecast$type_group[NEED_data_typecast$PROP_TYPE == "Mid terrace"] <- 5
NEED_data_typecast$type_group[NEED_data_typecast$PROP_TYPE == "Semi detached"] <- 6


epc_df_cl$type_group <- NULL
epc_df_cl$type_group[epc_df_cl$NEED_TYPE == "Bungalow"] <- 1
epc_df_cl$type_group[epc_df_cl$NEED_TYPE == "Detatched"] <- 2
epc_df_cl$type_group[epc_df_cl$NEED_TYPE == "End terrace"] <- 3
epc_df_cl$type_group[epc_df_cl$NEED_TYPE == "Flat"] <- 4
epc_df_cl$type_group[epc_df_cl$NEED_TYPE == "Mid terrace"] <- 5
epc_df_cl$type_group[epc_df_cl$NEED_TYPE == "Semi detached"] <- 6  
  
  
  # STAN MODEL INPUTS #####
  
  # APPLY SQRT NORMALISATION #
  
  NEED_data_typecast$E_TOT_sqrt <- sqrt(NEED_data_typecast$E_TOT)
  NEED_data_typecast$E_TOT_normal <- (NEED_data_typecast$E_TOT_sqrt - mean(NEED_data_typecast$E_TOT_sqrt))/sd(NEED_data_typecast$E_TOT_sqrt)
  
  epc_df_cl <- filter(epc_df_cl, as.numeric(epc_df_cl$`energy-consumption-current`) >= 0)
  epc_df_cl$E_CONS_sqrt <- sqrt(as.numeric(epc_df_cl$`energy-consumption-current`))
  epc_df_cl$E_CONS_normal <- (epc_df_cl$E_CONS_sqrt - mean(NEED_data_typecast$E_TOT_sqrt))/sd(NEED_data_typecast$E_TOT_sqrt)
  
  
  epc_priors <- stanc(file = "EPC_Prior_Sampling.stan") # Check Stan file
  epc_priors_model <- stan_model(stanc_ret = epc_priors)
  epc_priors_haringey<- sampling(epc_priors_model, iter=samples_mcmc, seed=2019, warmup=warmup_mcmc,
                                 chains=chains_mcmc,
                                 refresh = 100,
                                 data=list(N = length(NEED_data_typecast$E_TOT_normal), # Number of instances in the NEED Data
                                           M = length(epc_df_cl$E_CONS_normal),# Number of instances in the EPC data for specific region
                                           T = length(unique(NEED_data_typecast$type_group)),# Number of households typology groups
                                           E_N = NEED_data_typecast$E_TOT_normal ,
                                           E_M = epc_df_cl$E_CONS_normal,
                                           sigma_N = 1,
                                           tn = as.numeric(NEED_data_typecast$type_group),
                                           tm = as.numeric(epc_df_cl$type_group)
                                 ),
                                 control = list(#max_treedepth = 10,
                                   adapt_delta = 0.85
                                 )
  )
  
  #save(epc_priors_haringey, file="20210817_EPC_Haringey_Prior.RData")
  
  # EXTRACT DATAFRAME FROM MODEL OUTPUTS FOR PLOTS #
  
  epc_mcmc_dist <- epc_priors_haringey %>% 
    rstan::extract()  
  
  E_prior_mean <- as.data.frame(epc_mcmc_dist$E)
  E_prior_mean$sigma <- (epc_mcmc_dist$sigma)
  
  reverse_convert <- function(mu,sig){
    eint <- ((rnorm(1,mu,sig)*sd(NEED_data_typecast$E_TOT_sqrt))+mean(NEED_data_typecast$E_TOT_sqrt))^2
  }
  
  E_posterior <- as.data.frame(lapply(colnames(as.data.frame(epc_mcmc_dist$E)), function(i){mapply(reverse_convert, mu=E_prior_mean[,i], sig=E_prior_mean$sigma)}))
  colnames(E_posterior) <- c(1:6)
  
  require(reshape2)
  
  E_posterior_plot <- melt(E_posterior)
  colnames(E_posterior_plot) <- c("group","E_POS")
  E_posterior_plot$type_group <- as.numeric(as.character(E_posterior_plot$group))
  E_posterior_plot$LA <- i
  group_names <- list(
    "1" = "Bungalow",
    "2" = "Detached",
    "3" = "End Terrace",
    "4" = "Flat",
    "5" = "Mid Terrace",
    "6" = "Semi Detached"
  )

  facet_labeller <- function(variable,value){
    return(group_names[value])
  }

  ggplot() + stat_density(data= epc_df_cl, aes(x=as.numeric(`energy-consumption-current`), color="Local Authority EPCs", linetype="Local Authority EPCs"), size = 1,geom="line",position="identity")+
    stat_density(data=NEED_data_typecast, aes(x=E_TOT, color="NEED Prior", linetype="NEED Prior"), size = 1,geom="line",position="identity") +
    stat_density(data=E_posterior_plot, aes(x=E_POS, color="Posterior", linetype="Posterior"), size = 1,geom="line",position="identity") +
    scale_color_manual(labels= c("Local Authority EPCs","NEED Prior","Posterior"), values=c("#C7DED2","#67a684","#C700D2"), name="Legend")+
    scale_linetype_manual(labels= c("Local Authority EPCs","NEED Prior","Posterior"), values=c(4,3,1), name="Legend")+
    facet_wrap(~type_group, scales = "free_y", ncol = 1, labeller = facet_labeller) +
    xlim(0,500) +
    xlab("Energy Intensity kWh/m^2/year")+theme_minimal() 
    #ggsave("/data/outputs/base_distribution.png", width = 16, height = 16, dpi = 200)

  #head(E_posterior)
  E_posterior_all <- rbind(E_posterior_all, E_posterior_plot)
  print(paste("Worflow Finished for LA",i))
}

save(E_posterior_all, file="/data/outputs/base_dist_posterior.Rdata")