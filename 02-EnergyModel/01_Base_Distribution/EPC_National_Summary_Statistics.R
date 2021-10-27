# EPC_New_Builds_Statistics.R
# Script to pull and analyse sample from new build EPCs

require(dplyr)

set.seed(2019)

# Source EPC Search Function
source("EPC_Search_Fn.R")

# Load Local Authority List
LAD_List <- read.csv("nlac2011.csv") 

epc_summary_table <- NULL
age_bands=4
mean_NEED=132.991

# Create the mode function.
getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

# Loop through LADs
for(i in LAD_List$LAD20CD){
  
  epc_df <- EPC_Search(i)
  
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
  
  epc_df_cl$NEED_AGE_BANDS <- as.vector(unlist(lapply(epc_df_cl$`construction-age-band`, epc_age_band_convert)))
  
  if(age_bands==1){
    epc_df_cl <- filter(epc_df_cl, NEED_AGE_BANDS=="101")
  }else if(age_bands==2){
    epc_df_cl <- filter(epc_df_cl, NEED_AGE_BANDS=="102")
  }else if(age_bands==3){
    epc_df_cl <- filter(epc_df_cl, NEED_AGE_BANDS=="103")
  }else if(age_bands==4){
    epc_df_cl <- filter(epc_df_cl, NEED_AGE_BANDS=="104")
  }
  
  epc_summary_i <- epc_df_cl %>%
    summarise(wall_top_rating=mean(`walls-energy-eff`=="Very Good", na.rm=T),
              roof_top_rating=mean(`roof-energy-eff`=="Very Good", na.rm=T),
              floor_top_rating=mean(`floor-energy-eff`=="Very Good",na.rm=T),
              secondary_heating = mean(`secondheat-description`!="None", na.rm = T),
              mean_floor_height =mean(as.numeric(`floor-height`), na.rm=T),
              social_rental=mean(grepl("rent", epc_df_cl$tenure, ignore.case = TRUE) & grepl("social", epc_df_cl$tenure, ignore.case = TRUE), na.rm=T),
              private_rental=mean(grepl("rent", epc_df_cl$tenure, ignore.case = TRUE) & grepl("private", epc_df_cl$tenure, ignore.case = TRUE), na.rm=T),
              multiple_glazing_area=mean(as.numeric(epc_df_cl$`multi-glaze-proportion`),na.rm=T),
              standard_energy_tarriff=mean(`energy-tariff`=="standard tariff",na.rm = T),
              off_peak_tariff=mean(grepl("off-peak", epc_df_cl$`energy-tariff`, ignore.case = TRUE)),
              LA=getmode(`local-authority`),
              type="All")
  
  epc_summary_high_ene <- epc_df_cl %>%
    filter(as.numeric(`energy-consumption-current`)>= mean_NEED)%>%
    summarise(wall_top_rating=mean(`walls-energy-eff`=="Very Good", na.rm=T),
              roof_top_rating=mean(`roof-energy-eff`=="Very Good", na.rm=T),
              floor_top_rating=mean(`floor-energy-eff`=="Very Good",na.rm=T),
              secondary_heating = mean(`secondheat-description`!="None", na.rm = T),
              mean_floor_height =mean(as.numeric(`floor-height`), na.rm=T),
              social_rental=mean(grepl("rent", `tenure`, ignore.case = TRUE) & grepl("social", `tenure`, ignore.case = TRUE), na.rm=T),
              private_rental=mean(grepl("rent", `tenure`, ignore.case = TRUE) & grepl("private", `tenure`, ignore.case = TRUE), na.rm=T),
              multiple_glazing_area=mean(as.numeric(`multi-glaze-proportion`),na.rm=T),
              standard_energy_tarriff=mean(`energy-tariff`=="standard tariff",na.rm = T),
              off_peak_tariff=mean(grepl("off-peak", `energy-tariff`, ignore.case = TRUE)),
              LA=getmode(`local-authority`),
              type="High")
  
  epc_summary_table <- rbind(epc_summary_table,epc_summary_i,epc_summary_high_ene)
  print(paste("EPCs summarised for LA",i))
}
