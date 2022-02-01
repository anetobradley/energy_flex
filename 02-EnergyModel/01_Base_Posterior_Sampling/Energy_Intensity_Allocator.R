# Energy_Intensity_Allocator.R

# set synth pop target folder
setwd("C:/Users/apn30/OneDrive - University Of Cambridge/CSIC RA/National Energy Intensity Comparison")

lad_list <- list.files(path = "msm_england_uniform", pattern = ".csv")

floor_area_epc <- read.csv(file = "floor_area_distributions_uniform.csv", stringsAsFactors = F)

beis_e_tot <- 1680000000
beis_e <- data.frame("LA"=c("E06000002","E07000030","E07000040","E07000110","E07000131","E07000145","E07000146","E07000219","E09000005","E09000012","E09000014","E09000022","E09000027","E09000031"), "E_TOT" = c(989650031.45,542474941.98,1102080288.4,1279309270.5, 752107334.9,694623941.66, 1154150404.5, 940011012.39,2012389833.9,1356179271.3,1680032338.5,1883223596,1586590069.9,1628799084.9))

la_df <- NULL

for(i in lad_list){
  lad_loop <- strsplit(i, "_hh_msm_epc.csv")
  ei_post <- filter(E_Post, LA==lad_loop)
  ei_post[which(ei_post$E_POS > 1000),"E_POS"] <- rnorm(1,250,150)
  msm <- read.csv(file = paste0("msm_england_uniform/",i), stringsAsFactors = F)
  
  msm_typology_parser <- function(x,y){
    #if(x==2 && y==101){
    #  type = 1
    #}
    #else if(x==2 && y==102){
    #  type = 2
    #}
    #else if(x==2 && y==103){
    #  type = 3
    #}
    #else if(x==2 && y==104){
    #  type = 4
    #}
    if(x==2 && y<=1){
      type = 5
    }
    else if(x==2 && (2<=y & y<=4)){
      type = 6
    }
    else if(x==2 && (5<=y & y<=8)){
      type = 7
    }
    else if(x==2 && 9<=y){
      type = 8
    }
    #else if(x=="End terrace" && y==101){
    #  type = 9
    #}
    #else if(x=="End terrace" && y==102){
    #  type = 10
    #}
    #else if(x=="End terrace" && y==103){
    #  type = 11
    #}
    #else if(x=="End terrace" && y==104){
    #  type = 12
    #}
    else if(x==5 && y<=1){
      type = 13
    }
    else if(x==5 && (2<=y & y<=4)){
      type = 14
    }
    else if(x==5 && (5<=y & y<=8)){
      type = 15
    }
    else if(x==5 && 9<=y){
      type = 16
    }
    else if(x==4 && y<=1){
      type = 17
    }
    else if(x==4 && (2<=y & y<=4)){
      type = 18
    }
    else if(x==4 && (5<=y & y<=8)){
      type = 19
    }
    else if(x==4 && 9<=y){
      type = 20
    }
    else if(x==3 && y<=1){
      type = 21
    }
    else if(x==3 && (2<=y & y<=4)){
      type = 22
    }
    else if(x==3 && (5<=y & y<=8)){
      type = 23
    }
    else if(x==3 && 9<=y){
      type = 24
    }else{
      type=NA
    }
  }
  msm_household_typology <- function(need_df){
    need_df$group<-NULL
    need_df$group<-as.vector((mapply(msm_typology_parser, x=need_df$LC4402_C_TYPACCOM, y=need_df$ACCOM_AGE)))
    return(need_df)
  }
  msm_typecast <- filter(msm_household_typology(msm), !is.na(group))
  
  floor_area_LA <- filter(floor_area_epc, LAD.code==lad_loop)
  
  
  # Adjust area for energy consumption estimates.
  msm_typecast$FL_AREA <- 0
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 1)] <- floor_area_LA[,3]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 2)] <- floor_area_LA[,4]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 3)] <- floor_area_LA[,5]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 4)] <- floor_area_LA[,6]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 5)] <- floor_area_LA[,7]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 6)] <- floor_area_LA[,8]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 7)] <- floor_area_LA[,9]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 8)] <- floor_area_LA[,10]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 9)] <- floor_area_LA[,11]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 10)] <- floor_area_LA[,12]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 11)] <- floor_area_LA[,13]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 12)] <- floor_area_LA[,14]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 13)] <- floor_area_LA[,15]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 14)] <- floor_area_LA[,16]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 15)] <- floor_area_LA[,17]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 16)] <- floor_area_LA[,18]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 17)] <- floor_area_LA[,19]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 18)] <- floor_area_LA[,20]
  msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 19)] <- floor_area_LA[,21]
  
  
  # Applicator to derive ward totals
  # Set samples from posterior
  sample_no = 100
  df_assign = NULL
  la_ei = NULL
  ei_post <- ei_post[order(ei_post$group),]
  ei_post$COUNT <- rep(1:(length(ei_post$group)/24),24)
  ei_post_cast <- dcast(ei_post, COUNT~group, value.var="E_POS")
  
  print(paste("Applicator started for", lad_loop))
  
  for(n in 1:sample_no){
    l_pst <- length(ei_post_cast$COUNT)
    ranrow <- sample(1:l_pst, 1)
    for(l in 1:nrow(msm_typecast)){
      g <- msm_typecast$group[l]
      df_assign[l] = ei_post_cast[ranrow,g]*msm_typecast$FL_AREA[l]
    }
    la_ei[n] <- sum(df_assign)
  }
  
  la_ei_df <- data.frame("LA"=c(lad_loop),"MSM"=la_ei, "BEIS"=beis_e$E_TOT[which(beis_e$LA==lad_loop)])
  
  la_df <- rbind(la_df, la_ei_df)
  
  print(paste("Applicator completed for", lad_loop))
}
  
  

# Load Energy Intensity Posteriors
# read.csv(file = )
#ei_post <- filter(E_Post, LA=="E09000027")

# Resample for Stan OOBs

#ei_post[which(ei_post$E_POS > 1000),"E_POS"] <- rnorm(1,250,150)

# Load Synthetic Population
# msm <- read.csv(file = "E09000027_hh_msm_epc.csv", stringsAsFactors = F)
# 
# # Group Synthetic Population by housing type and age
# # Assign group numbers based on Building Type and Age
# msm_typology_parser <- function(x,y){
#   #if(x==2 && y==101){
#   #  type = 1
#   #}
#   #else if(x==2 && y==102){
#   #  type = 2
#   #}
#   #else if(x==2 && y==103){
#   #  type = 3
#   #}
#   #else if(x==2 && y==104){
#   #  type = 4
#   #}
#   if(x==2 && y<=1){
#     type = 5
#   }
#   else if(x==2 && (2<=y & y<=4)){
#     type = 6
#   }
#   else if(x==2 && (5<=y & y<=8)){
#     type = 7
#   }
#   else if(x==2 && 9<=y){
#     type = 8
#   }
#   #else if(x=="End terrace" && y==101){
#   #  type = 9
#   #}
#   #else if(x=="End terrace" && y==102){
#   #  type = 10
#   #}
#   #else if(x=="End terrace" && y==103){
#   #  type = 11
#   #}
#   #else if(x=="End terrace" && y==104){
#   #  type = 12
#   #}
#   else if(x==5 && y<=1){
#     type = 13
#   }
#   else if(x==5 && (2<=y & y<=4)){
#     type = 14
#   }
#   else if(x==5 && (5<=y & y<=8)){
#     type = 15
#   }
#   else if(x==5 && 9<=y){
#     type = 16
#   }
#   else if(x==4 && y<=1){
#     type = 17
#   }
#   else if(x==4 && (2<=y & y<=4)){
#     type = 18
#   }
#   else if(x==4 && (5<=y & y<=8)){
#     type = 19
#   }
#   else if(x==4 && 9<=y){
#     type = 20
#   }
#   else if(x==3 && y<=1){
#     type = 21
#   }
#   else if(x==3 && (2<=y & y<=4)){
#     type = 22
#   }
#   else if(x==3 && (5<=y & y<=8)){
#     type = 23
#   }
#   else if(x==3 && 9<=y){
#     type = 24
#   }else{
#     type=NA
#   }
# }
# 
# 
# msm_household_typology <- function(need_df){
#   need_df$group<-NULL
#   need_df$group<-as.vector((mapply(msm_typology_parser, x=need_df$LC4402_C_TYPACCOM, y=need_df$ACCOM_AGE)))
#   return(need_df)
# }
# 
# msm_typecast <- filter(msm_household_typology(msm), !is.na(group))
# 
# 
# floor_area_epc <- read.csv(file = "floor_area_distributions_filtered.csv", stringsAsFactors = F)
# floor_area_LA <- filter(floor_area_epc, LAD.code=="E09000027")
# 
# 
# # Adjust area for energy consumption estimates.
# msm_typecast$FL_AREA <- 0
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 1)] <- floor_area_LA$`X1..A....40.m²`
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 2)] <- floor_area_LA$X2..40...A....50
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 3)] <- floor_area_LA$X3..50...A....60
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 4)] <- floor_area_LA$X4..60...A....70
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 5)] <- floor_area_LA$X5..70...A....80
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 6)] <- floor_area_LA$X6..80...A....90
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 7)] <- floor_area_LA$X7..90...A....100
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 8)] <- floor_area_LA$X8..100...A....110
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 9)] <- floor_area_LA$X9..110...A....120
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 10)] <- floor_area_LA$X10..120...A....130
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 11)] <- floor_area_LA$X11..130...A....140
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 12)] <- floor_area_LA$X12..140...A....150
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 13)] <- floor_area_LA$X13..150...A....200
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 14)] <- floor_area_LA$X14..200...A....300
# msm_typecast$FL_AREA[which(msm_typecast$FLOOR_AREA == 15)] <- floor_area_LA$X15..300...A....400
# 
# 
# # Applicator to derive ward totals
# 
# # Set samples from posterior
# sample_no = 500
# df_assign = NULL
# la_ei = NULL
# ei_post <- ei_post[order(ei_post$group),]
# ei_post$COUNT <- rep(1:(length(ei_post$group)/24),24)
# ei_post_cast <- dcast(ei_post, COUNT~group, value.var="E_POS")
# 
# for(n in 1:sample_no){
#   l_pst <- length(ei_post_cast$COUNT)
#   ranrow <- sample(1:l_pst, 1)
#   for(l in 1:nrow(msm_typecast)){
#     g <- msm_typecast$group[l]
#     df_assign[l] = ei_post_cast[ranrow,g]*msm_typecast$FL_AREA[l]
#   }
#   la_ei[n] <- sum(df_assign)
# }
# 
# la_E09000027_ei <- la_ei
# 
# beis_e_tot <- 1680000000
# beis_e <- data.frame("LA"=c("E06000002","E07000030","E07000040","E07000110","E07000131","E07000145","E07000146","E07000219","E09000005","E09000012","E09000014","E09000022","E09000027","E09000031"), "E_TOT" = c(989650031.45,542474941.98,1102080288.4,1279309270.5, 752107334.9,694623941.66, 1154150404.5, 940011012.39,2012389833.9,1356179271.3,1680032338.5,1883223596,1586590069.9,1628799084.9))
# 
# la_E09000027_ei_df <- data.frame("LA"=c("E09000027"),"MSM"=la_E09000027_ei, "BEIS"=beis_e$E_TOT[which(beis_e$LA=="E09000027")])
# 
# la_df <- rbind(la_E06000002_ei_df,
#                la_E07000030_ei_df,
#                la_E07000040_ei_df,
#                la_E07000110_ei_df,
#                la_E07000131_ei_df,
#                la_E07000145_ei_df,
#                la_E07000146_ei_df,
#                la_E07000219_ei_df,
#                la_E09000014_ei_df,
#                la_E09000005_ei_df,
#                la_E09000012_ei_df,
#                la_E09000022_ei_df,
#                la_E09000027_ei_df)

ggplot() + geom_density(aes(x=la_E07000219_ei, fill="MSM"), alpha=0.5) + geom_vline(aes(xintercept=beis_e_tot, colour="BEIS Estimate")) + #xlim(700000000,2500000000) +
  xlab("GWh per Year") + ggtitle("Total Annual Residential Consumption for Haringey ") +
  theme_minimal()


ggplot() + geom_density(data=ei_post, aes(x=E_POS, fill=as.factor(group), group=group), alpha=0.5) + xlab("GWh per Year") + ggtitle("Total Annual Residential Consumption for Haringey ") +
  xlim(0,1000) + theme_minimal()


ggplot() + geom_boxplot(data=la_df,aes(x=BEIS, y= MSM, colour=LA)) + 
  geom_line(aes(x=c(0,3000000000),y=c(0,3000000000)))+
  geom_line(aes(x=c(0,2700000000),y=c(0,3000000000)), linetype=3)+
  geom_line(aes(x=c(0,3000000000),y=c(0,2700000000)), linetype=3)+
  xlim(0,3000000000) + ylim(0,3000000000) +
  labs(
    title = "Total Annual Residential Energy Consumption",
    subtitle = "Estimate from MSM versus BEIS Statistic (kWh per year)"
  )+
  theme_minimal()
