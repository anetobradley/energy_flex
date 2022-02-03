# Energy_Intensity_Weather_Test.R
# Need to check correlation between heating degree days and energy intensity
# For this we need to get mean heating degree days for 
# https://datashare.ed.ac.uk/handle/10283/2813?show=full

library(tidyverse)
library(ncdf4)
library(reshape2)

cdf <- nc_open("DS_10283_2813/dd_ppe_1981-2010AND2040-2069_CORRECTEDSIG.nc")

lat_cdf <- ncvar_get(cdf, varid = "lat")
lon_cdf <- ncvar_get(cdf, varid = "lon")
hdd_cdf <- ncvar_get(cdf, varid = "Hobs")

# Import lattitude and longitude for actual RG2 grid
lat_real <- read.csv("DS_10283_2813/real_latitudes.csv", stringsAsFactors = F, header = F)
lon_real <- read.csv("DS_10283_2813/real_longitudes.csv", stringsAsFactors = F, header = F)


lat_real$V1 <- 1:52
colnames(lat_real) <- c("rotlat", 1:39)


hdd_cdf[0:33, 0:39, 1]

cdf_df <- expand.grid(0:39, 0:33)
names(cdf_df) <- c("lat", "lon")
cdf_df$hdd <- NA
head(cdf_df)

for(i in 1:nrow(cdf_df)){
 #lat_ind <- which(lat_cdf == cdf_df[i,"lat"])
  #lon_ind <- which(lon_cdf == cdf_df[i,"lon"])
  lat_ind <- cdf_df[i,"lat"]+1
  lon_ind <- cdf_df[i,"lon"]+1
  
  cdf_df[i,"hdd"] <- hdd_cdf[lon_ind, lat_ind, 1] + 
    hdd_cdf[lon_ind, lat_ind, 2] + 
    hdd_cdf[lon_ind, lat_ind, 3] +
    hdd_cdf[lon_ind, lat_ind, 4] + 
    hdd_cdf[lon_ind, lat_ind, 5] +
    hdd_cdf[lon_ind, lat_ind, 6] + 
    hdd_cdf[lon_ind, lat_ind, 7] +
    hdd_cdf[lon_ind, lat_ind, 8] + 
    hdd_cdf[lon_ind, lat_ind, 9] +
    hdd_cdf[lon_ind, lat_ind, 10] + 
    hdd_cdf[lon_ind, lat_ind, 11] +
    hdd_cdf[lon_ind, lat_ind, 12] 
}

head(cdf_df)

cdf_df$lat <- cdf_df$lat + 6
cdf_df$lon <- cdf_df$lon + 3

cdf_df$lat_real <- NA
cdf_df$lon_real <- NA

for(i in 1:nrow(cdf_df)){
  lat_ind <- cdf_df[i,"lat"]+1
  lon_ind <- cdf_df[i,"lon"]+1
  
  cdf_df[i,"lat_real"] <- lat_real[52-lat_ind, lon_ind]
  cdf_df[i,"lon_real"] <- lon_real[52-lat_ind, lon_ind]
}


# 
# library(maps)
# library(mapdata)
# map('world2Hires', xlim=range(350:370) + c(-10, 10), ylim=range(48:59) + c(-5, 5))
# box()
# points(cdf_df$lon_real, cdf_df$lat_real)
# 
# 
# ncolors <- 5
# cols <- cut(cdf_df$hdd, ncolors)
# palette <- colorRampPalette((c("blue", "red")))(ncolors)
# 
# map('world2Hires', xlim=range(350:365) + c(-10, 10), ylim=range(48:59) + c(-5, 5))
# box()
# 
# 
# grid_hw <- 0.1 # Grid half width
# rect(cdf_df$lon_real - grid_hw, cdf_df$lat_real - grid_hw, cdf_df$lon_real + grid_hw, cdf_df$lat_real + grid_hw, col=palette[cols])
# 
# map.axes()
# title(main="June SST Values", xlab="Longitude", ylab="Lattitude")
# legend("topright", legend=levels(cols), fill=palette)


# Now to match local authorities to their nearest point

laddf_centroids <- sf::st_centroid(laddf$geometry) 

library(stringr)

laddf_centroids <- str_split_fixed(laddf_centroids,", ", 2) 
laddf_centroids <- as.data.frame(laddf_centroids)

laddf_centroids$V1 <- gsub("c\\(","",laddf_centroids$V1) %>% as.numeric()
laddf_centroids$V2 <- gsub("\\)","",laddf_centroids$V2) %>% as.numeric()


laddf$lon_cent <- laddf_centroids$V1
laddf$lat_cent <- laddf_centroids$V2


cdf_df$lon_real[which(cdf_df$lon_real > 300)] <-cdf_df$lon_real[which(cdf_df$lon_real > 300)]-360

distp1p2 <- function(p1,p2) {
  dst <- sqrt((p1[1]-p2[1])^2+(p1[2]-p2[2])^2)
  return(dst)
}

dist2 <- function(y) which.min(apply(filter(cdf_df[,5:4], !is.na(cdf_df$hdd)), 1, function(x) min(distp1p2(x,y))))

laddf$nearest <- apply(laddf_centroids, 1, dist2)
laddf$hdd <- filter(cdf_df, !is.na(cdf_df$hdd))[laddf$nearest,3]
laddf_hdd <- laddf$hdd
#laddf_hdd <- laddf_hdd$hdd
laddf_hdd <- data.frame("id"=laddf$id,"hdd"=laddf_hdd)

laddf_hdd_plot <- left_join(laddf_plot,laddf_hdd,  by=c("id"))

test <-cor.test(laddf_hdd_plot$hdd, laddf_hdd_plot$E_int )
plot( laddf_hdd_plot$hdd, laddf_hdd_plot$E_int )

load(file="Heating_Degree_Days_by_LAD.Rda")
# Paper plot
phdd <- ggplot() +
  geom_sf(data=laddf_hdd_plot, aes(group = id, fill=hdd), colour="white", size=0.5) +
  #geom_point(data = cdf_df, aes(x=cdf_df$lon_real, y=cdf_df$lat_real, colour=hdd), size=5) +
  scale_fill_gradientn(colours = rev(MetBrewer::met.brewer("Hiroshige", type="continuous")),na.value="white", name = "Heating Degree Days")+
  #scale_alpha(limits=c(20,100), breaks=2, name = "Energy Intensity")+
  #facet_wrap(~age, nrow=2) +
  theme_void() +   labs(
    title = "Heating Degree Days",
    subtitle = "Estimated Heating Degree Days by Local Authority using a baseline temperature of 15.5C"
  ) +
  theme(legend.position="bottom", legend.title = element_text(size=12, hjust=1),
        plot.margin = unit(c(0,-2,0,-2), "cm"))+ guides(fill= guide_colourbar(barwidth = 10, barheight = 1, title.position = "left"))+
  coord_sf()

lad_hdd_age <- left_join(laddf_plot_epc_allage, laddf_hdd, by="id")
lad_hdd_dispinc <- data.frame("inc" =laddf_extras_3$V4_2, "id" = laddf_extras_3$id)
lad_hdd_age <- left_join(lad_hdd_age, lad_hdd_dispinc, by="id")
lad_hdd_age$age <- factor(lad_hdd_age$age, levels = c("pre-1930","1930-1972","1973-1999","post-2000"))

ggplot()+
  geom_point(data=lad_hdd_age, aes(x=hdd, y=E_int, colour=inc)) +
  geom_smooth(data=lad_hdd_age, aes(x=hdd, y=E_int), method="lm")+
  scale_colour_gradientn(colours = (MetBrewer::met.brewer("Hokusai2", type="continuous")),na.value="white", name = "Mean Annual Household \nDisposable Income \n(before housing)")+
  facet_wrap(~age, nrow=1) +
  theme_minimal() 

data.frame("E_int" = lad_hdd_age$E_int, "hdd" = lad_hdd_age$hdd, "age" = lad_hdd_age$age) %>%
  group_by(age) %>%
  summarise("test" = as.numeric(cor.test(hdd, E_int)["estimate"]))


cor.test(lad_hdd_age$hdd, lad_hdd_age$E_int)

lad_inc_hdd <- left_join(laddf_extras_3, laddf_hdd, by="id")
