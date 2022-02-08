# National_Output_Plots.R
# Up to date as of 7/2/2022

# A script file

# Load Libraries
library(tidyverse)
library(geojsonio)
library(sp)
library(broom)
library(mapproj)
library(rgeos)
library(rgdal)
library(ggmap)
library(jsonlite)
library(wesanderson)
library(gridExtra)
library(patchwork)
library(geogrid)
library(sf)
library(tmap)
library(showtext)
library(broom)
font_add_google("Lato", family="Montserrat")
showtext_auto()

#### DATA WRANGLING ####
# TBC

#### MAP WITH COLOUR SCALE FOR NEW BUILDS ####

# Set up lists with labels for binned colour scale.
tags <- c("-50","-25", "0", "25","50")

# Re-label Energy Intensity with bin midpoints for simplified colour scale.
laddf_plot_epc <- laddf_plot_epc %>% 
  mutate(E_REL_bin = case_when(
    E_REL < -37.5 ~ tags[1],
    E_REL >= -37.5 & E_REL < -12.5 ~ tags[2],
    E_REL >= -12.5 & E_REL < 12.5 ~ tags[3],
    E_REL >= 12.5 & E_REL < 37.5 ~ tags[4],
    E_REL >= 37.5 ~ tags[5]
  ))

# Base ggplot with actual Local Authority Maps
p1 <- ggplot() +
  geom_sf(data=laddf_plot_epc_allage, aes(group = id, fill=E_REL_bin, alpha=100*(1-wall_top_rating)), colour="white") +
  scale_fill_manual(values = wes_palette("Zissou1", 5, type = "discrete"),na.value="white", guide="colourbar", name = "Energy Intensity \nrelative to National \nAverage (kWh/m^2)")+
  scale_alpha(limits=c(20,100), breaks=2, name = "Energy Intensity \nrelative to National \nAverage (kWh/m^2)")+
  theme_void() +   labs(
    title = "Spatial Inequality in Energy Efficiency",
    subtitle = "Difference between local and national energy intensity for post-2000 homes by local authority"
  ) +
  theme(legend.position="none", legend.title = element_text(size=12, hjust=1),
        plot.margin = unit(c(0,-2,0,-2), "cm"))+ guides(fill= guide_colourbar(barwidth = 10, barheight = 1, title.position = "left"))+
  coord_sf()

# List of labels
p1_scale_data <- data.frame("fill"=c("-50","-25", "0", "25","50","-50","-25", "0", "25","50"),
                            "alpha"=c("<60%","<60%","<60%","<60%","<60%",">60%",">60%",">60%",">60%",">60%"))

p1_scale <- ggplot(p1_scale_data) + geom_tile(aes(y=fill, x=alpha, fill=fill, alpha=alpha),color = "white",
                                              lwd = 1.5,
                                              linetype = 1) +
  scale_fill_manual(values = wes_palette("Zissou1", 5, type = "discrete"),na.value="white")+
  scale_alpha_manual(values= c(0.5,1))+ xlab("Homes without \ntop-rated \ninsulation (%)") + ylab(expression(paste("Energy Intensity \nRelative to National \nAverage (kWh/",m^2,"/year)", sep=""))) +
  theme_void() + theme(axis.title.y = element_text(angle=-90,vjust = -10, hjust = 0, colour = "grey30"), 
                       axis.text.y = element_text(angle=-90, vjust = -1, colour = "grey30"), 
                       axis.title.x = element_text(angle=0, vjust = -2, hjust=0, colour = "grey30"), 
                       axis.text.x = element_text(angle=0, vjust = -1, colour = "grey30"), 
                       legend.position = "none",
                       axis.line = element_line(arrow = grid::arrow(length = unit(0.2, "cm"), 
                                                                    ends = "last"),colour = "grey70"),
                       plot.margin = unit(c(1,0,1,0), "cm"),
                       aspect.ratio=2.5)


grid.arrange(p1_scale,p1, heights=c(1,2), ncol=2)
#grid.arrange( p1, arrangeGrob(blankPlot, p1_scale, blankPlot, heights = c(1,2,1)), ncol = 2, widths=c(5,1))

p1+inset_element(p1_scale,  0, 0.25, 0.4, 0.75,
                 align_to = "full")


#### MAPS WITH COLOUR SCALE FACETTED BY AGE BAND ####

p4 <- ggplot() +
  geom_sf(data=laddf_plot_epc_allage, aes(group = id, fill=E_int), colour="white", size=0.1) +
  scale_fill_gradientn(colours = rev(MetBrewer::met.brewer("Hiroshige", type="continuous")),na.value="white", name = "Energy Intensity (kWh/m^2)")+
  #scale_alpha(limits=c(20,100), breaks=2, name = "Energy Intensity")+
  facet_wrap(~age, nrow=2) +
  theme_void() +   labs(
    title = "Energy Intensity Estimates by Dwelling Age",
    subtitle = "Mean energy intensity for flats, semi-detached, and mid-terrace housing in each local authority"
  ) +
  theme(legend.position="bottom", legend.title = element_text(size=12, hjust=1),
        plot.margin = unit(c(0,-2,0,-2), "cm"))+ guides(fill= guide_colourbar(barwidth = 10, barheight = 1, title.position = "left"))+
  coord_sf()

#### LOLLIPOP RANGE CHART FOR DIFFERENCE BETWEEN AGE BAND BY LOCAL AUTHORITY ####

# Wrangle data for north-east

# Select posterior samples from north-east local authorities
nw_post <- E_Post %>% filter(LA %in% c("E08000016",
                                       "E08000032",
                                       "E08000033",
                                       "E07000163",
                                       "E08000017",
                                       "E06000011",
                                       "E07000164",
                                       "E07000165",
                                       "E06000010",
                                       "E08000034",
                                       "E08000035",
                                       "E06000012",
                                       "E06000013",
                                       "E07000166",
                                       "E08000018",
                                       "E07000167",
                                       "E07000168",
                                       "E07000169",
                                       "E08000019",
                                       "E08000036",
                                       "E06000014"
))

# Get information for lolly points (mean values by age)
nw_lolly <- nw_post %>% 
  filter(group %in% c(17,20)) %>% 
  group_by(LA, group) %>% 
  summarise("Mean"=mean(E_POS))

nw_lollystick <- nw_lolly %>% filter(group %in% c(17,20))  %>% group_by(LA) %>% summarise("max"=max(Mean), "min"=min(Mean), "diff"=max(Mean)-min(Mean))

nw_low <- nw_lolly %>% filter(group %in% c(20))  %>% group_by(group) %>% summarise("max"=max(Mean), "min"=min(Mean), "sd"=sd(Mean), "mu" =mean(Mean))
nw_high <- nw_lolly %>% filter(group %in% c(17))  %>% group_by(group) %>% summarise("max"=max(Mean), "min"=min(Mean), "sd"=sd(Mean), "mu" =mean(Mean))


# Create base ggplot
jan2 <- ggplot() +  
  geom_vline(xintercept = nw_low$mu, linetype = "solid", size = 1, alpha = .8, color = met.brewer("Hiroshige",7)[c(6)])+
  #geom_vline(xintercept = nw_low$mu, linetype = "solid", size = 2*nw_low$sd, alpha = .1, color = met.brewer("Hiroshige",7)[c(5)])+
  geom_vline(xintercept = nw_high$mu, linetype = "solid", size = 1, alpha = .8, color = met.brewer("Hiroshige",7)[c(2)])+
  #geom_vline(xintercept = nw_high$mu, linetype = "solid", size = 2*nw_high$sd, alpha = .1, color = met.brewer("Hiroshige",7)[c(2)])+
  
  geom_segment(data = nw_lollystick,
               aes(x = min, y =reorder(state_lookup[LA],diff),
                   yend = reorder(state_lookup[LA],diff), xend =max), #use the $ operator to fetch data from our "Females" tibble
               color = met.brewer("Hiroshige",11)[5],
               size = 4.5, #Note that I sized the segment to fit the points
               alpha = .5) +
  
  geom_rect(aes(xmin = nw_low$mu-nw_low$sd, xmax = nw_low$mu+nw_low$sd,
                ymin = 0, ymax = 22), fill = met.brewer("Hiroshige",7)[c(5)], alpha = .1)+
  geom_rect(aes(xmin = nw_high$mu-nw_high$sd, xmax = nw_high$mu+nw_high$sd,
                ymin = 0, ymax = 22), fill = met.brewer("Hiroshige",7)[c(2)], alpha = .1)+
  
  
  
  geom_point(data=nw_lolly,aes(y = state_lookup[LA], x = Mean, color = as.factor(group)), size = 5, show.legend = TRUE)+
  
  #add annotations for mean and standard deviations
  geom_text(aes(x = nw_high$mu+1, y = 0.5), vjust=0, hjust=1,label = "Mean", angle = 270, size = 3, color = met.brewer("Hiroshige",4)[c(1)])+
  geom_text(aes(x = nw_high$mu+nw_high$sd-5, y = 0.5),vjust=0, hjust=1, label = "Standard Deviation", angle = 270, size = 3, color = met.brewer("Hiroshige",4)[c(1)])+  #coord_flip()+
  xlab(bquote('Energy Intensity ('~' kWh/'~m^2~'/year '*')'))+
  scale_color_manual(values=met.brewer("Hiroshige",7)[c(1,7)])+
  theme_minimal()  +
  theme(text = element_text(family = 'Montserrat', color = "black"),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none",
        axis.text.y = element_text(size=10, color="black"),
        axis.ticks.y = element_blank(),
        axis.ticks.x = element_line(),
        #strip.text.y.left  = element_text(angle = 0),
        panel.background = element_rect(fill = "white", color = "white"),
        strip.background = element_rect(fill = "white", color = "white"),
        #strip.text = element_text(color = "#4a4e4d", family = "Segoe UI"),
        plot.background = element_rect(fill = "white", color = "white"),
        #panel.spacing = unit(0, "lines"))
        plot.margin = margin(1,1,0.5,1, "cm")) 


# Add ggtext titles and caption with formatting
jan2+
  #add subtitle and caption
  labs(title = "Efficiency of new and old homes vary by where you live",
       subtitle = "Energy Intensity of <span style = 'color: #1E466E;'>**post-2000**</span> and <span style = 'color:#E76254;'>**pre-1930s**</span> semi-detached homes<br>",
       caption = "<br>Visualization: Andre Neto-Bradley  .  Data: Modelled based on EPC & NEED datasets")+
  
  #add theming for title, subtitle, caption
  theme(plot.caption = element_markdown(hjust = 1, vjust = 1, lineheight = 1),
        plot.subtitle = element_markdown(size = 12, hjust = -.06),
        plot.title = element_text(size = 16, hjust = -.11, face = "bold"))


#### REGIONAL HEXMAP WITH TESSELATED SUBTILES FOR INTENDSITY BY TYPOLOGIES ####
# Hexmap of Energy Intensities by Buidling Type and Age
# Displays outputs from energy intensity estimation for each local authority.
# Based upon Tidy Tuesday Hexmap by rivasiker
# https://github.com/rivasiker/TidyTuesday/tree/main/2022/2022-01-11

# First we need to create a hex spatial map of england LADs
input_file <- system.file("extdata", "london_LA.json", package = "geogrid")
original_shapes <- laddf_plot %>% st_set_crs(27700)
original_shapes$SNAME <- substr(original_shapes$LAD13NM, 1, 4)

rawplot <- tm_shape(filter(original_shapes,id %in% c("E08000016",
                                                     "E08000032",
                                                     "E08000033",
                                                     "E07000163",
                                                     "E08000017",
                                                     "E06000011",
                                                     "E07000164",
                                                     "E07000165",
                                                     "E06000010",
                                                     "E08000034",
                                                     "E08000035",
                                                     "E06000012",
                                                     "E06000013",
                                                     "E07000166",
                                                     "E08000018",
                                                     "E07000167",
                                                     "E07000168",
                                                     "E07000169",
                                                     "E08000019",
                                                     "E08000036",
                                                     "E06000014"
))) + 
  tm_polygons("E_REL", palette = "viridis") +
  tm_text("SNAME")
rawplot

par(mfrow = c(2, 3), mar = c(0, 0, 2, 0))
for (i in 1:6) {
  new_cells <- calculate_grid(shape = filter(original_shapes,id %in% c("E08000016",
                                                                       "E08000032",
                                                                       "E08000033",
                                                                       "E07000163",
                                                                       "E08000017",
                                                                       "E06000011",
                                                                       "E07000164",
                                                                       "E07000165",
                                                                       "E06000010",
                                                                       "E08000034",
                                                                       "E08000035",
                                                                       "E06000012",
                                                                       "E06000013",
                                                                       "E07000166",
                                                                       "E08000018",
                                                                       "E07000167",
                                                                       "E07000168",
                                                                       "E07000169",
                                                                       "E08000019",
                                                                       "E08000036",
                                                                       "E06000014"
  )), grid_type = "hexagonal", seed = i)
  plot(new_cells, main = paste("Seed", i, sep = " "))
}

new_cells_hex <- calculate_grid(shape = filter(original_shapes,id %in% c("E08000016",
                                                                         "E08000032",
                                                                         "E08000033",
                                                                         "E07000163",
                                                                         "E08000017",
                                                                         "E06000011",
                                                                         "E07000164",
                                                                         "E07000165",
                                                                         "E06000010",
                                                                         "E08000034",
                                                                         "E08000035",
                                                                         "E06000012",
                                                                         "E06000013",
                                                                         "E07000166",
                                                                         "E08000018",
                                                                         "E07000167",
                                                                         "E07000168",
                                                                         "E07000169",
                                                                         "E08000019",
                                                                         "E08000036",
                                                                         "E06000014"
)), grid_type = "hexagonal", seed = 3)
resulthex_nw <- assign_polygons(filter(original_shapes,id %in% c("E08000016",
                                                                 "E08000032",
                                                                 "E08000033",
                                                                 "E07000163",
                                                                 "E08000017",
                                                                 "E06000011",
                                                                 "E07000164",
                                                                 "E07000165",
                                                                 "E06000010",
                                                                 "E08000034",
                                                                 "E08000035",
                                                                 "E06000012",
                                                                 "E06000013",
                                                                 "E07000166",
                                                                 "E08000018",
                                                                 "E07000167",
                                                                 "E07000168",
                                                                 "E07000169",
                                                                 "E08000019",
                                                                 "E08000036",
                                                                 "E06000014"
)), new_cells_hex)

spdf_hex <- as_Spatial(resulthex_nw)
#new_cells_reg <- calculate_grid(shape = original_shapes, grid_type = "regular", seed = 3)
#resultreg <- assign_polygons(original_shapes, new_cells_reg)

spdf_fortified <- tidy(spdf_hex, region = "LAD13CD") 
# Calculate the centroid of each hexagon to add the label:
centers <- cbind.data.frame(data.frame(gCentroid(spdf_hex, byid=TRUE), id=spdf_hex@data$LAD13NM))

# Now I can plot this shape easily as described before:
ggplot() +
  geom_polygon(data = filter(spdf_fortified, id %in% c("E08000016",
                                                       "E08000032",
                                                       "E08000033",
                                                       "E07000163",
                                                       "E08000017",
                                                       "E06000011",
                                                       "E07000164",
                                                       "E07000165",
                                                       "E06000010",
                                                       "E08000034",
                                                       "E08000035",
                                                       "E06000012",
                                                       "E06000013",
                                                       "E07000166",
                                                       "E08000018",
                                                       "E07000167",
                                                       "E07000168",
                                                       "E07000169",
                                                       "E08000019",
                                                       "E08000036",
                                                       "E06000014"
  )), aes( x = long, y = lat, group = group), fill="skyblue", color="white") +
  geom_text(data=centers, aes(x=x, y=y, label=id)) +
  theme_void() +
  coord_map()

# Need to sumarise the posterior data by year and by type

haringey_post <- E_Post %>% filter(LA=="E07000167")
haringey_colony <- haringey_post %>% filter(group %in% c(5,6,7,8,13,14,15,16,17,18,19,20,21,22,23,24))  %>% group_by(group) %>% summarise("Mean"=mean(E_POS))


# This function divides a hexagon into 24 triangles (borrowed from https://github.com/rivasiker/TidyTuesday/tree/main/2022/2022-01-11)
triangle <- function(x) {
  
  # this is for reordering the groups of the triangles
  lookup <- setNames(1:24, 
                     c(13, 1, 8, 2, 11, 3, 12, 4, 10, 7, 19, 22, 
                       16, 24, 15, 23, 14, 20, 17, 5, 9, 6, 18, 21)
  )
  lookup_2 <- setNames( c(21, 22, 3, 4, 8, 12, 16, 20, 19, 23, 24, 18, 17, 13, 
                          9, 5, 1, 2, 6, 7, 11, 15, 14, 10), 1:24
                        
  )
  
  # This is a (rather ugly) chunk for calculating the triangle boundaries
  dat <- rbind(
    x[1,1:2],
    tibble(
      long = x[[1,1]]-(x[[1,1]]-x[[2,1]])/2,
      lat = x[[1,2]]-(x[[1,2]]-x[[2,2]])/2,
    ),
    tibble(long = x[[1,1]], lat = x[[2,2]]),
    x[1,1:2]
  )
  dat_2 <- 
    rbind(
      mutate(dat, group = 1),
      mutate(dat, 
             long = long-(x[[1,1]]-x[[2,1]])/2,
             lat = lat-(x[[1,2]]- x[[2,2]])/2,
             group = 2),
      mutate(dat, 
             long = long-(x[[1,1]]-x[[2,1]])/2,
             lat = lat-(x[[1,2]]- x[[2,2]])*1.5,
             group = 3),
      mutate(dat, 
             long = long-(x[[1,1]]-x[[2,1]])/2,
             lat = lat-(x[[1,2]]- x[[2,2]])*2.5,
             group = 4),
      mutate(dat, 
             lat = lat-(x[[1,2]]- x[[2,2]]),
             group = 5),
      mutate(dat, 
             lat = lat-(x[[1,2]]- x[[2,2]])*2,
             group = 6),
      mutate(dat, 
             lat = lat-(x[[1,2]]- x[[2,2]])*3,
             group = 7),
      
      mutate(dat, 
             long = -long+(x[[1,1]])*2-
               (x[[1,1]]-x[[2,1]])/2,
             lat = lat-(x[[1,2]]- x[[2,2]])/2,
             group = 8),
      mutate(dat, 
             long = -long+(x[[1,1]])*2-
               (x[[1,1]]-x[[2,1]])/2,
             lat = lat-(x[[1,2]]- x[[2,2]])*1.5,
             group = 9),
      mutate(dat, 
             long = -long+(x[[1,1]])*2-
               (x[[1,1]]-x[[2,1]])/2,
             lat = lat-(x[[1,2]]- x[[2,2]])*2.5,
             group = 10),
      mutate(dat, 
             long = -long+(x[[1,1]])*2-
               (x[[1,1]]-x[[2,1]]),
             lat = lat-(x[[1,2]]- x[[2,2]]),
             group = 11),
      mutate(dat, 
             long = -long+(x[[1,1]])*2-
               (x[[1,1]]-x[[2,1]]),
             lat = lat-(x[[1,2]]- x[[2,2]])*2,
             group = 12)
    )
  dat_2 <- rbind(
    dat_2,
    mutate(
      dat_2,
      long = x[[1,1]]*2-long,
      group = group+12
    )
  ) %>% 
    mutate(
      lat = (lat-x[[1,2]])*0.02+lat,
      group = lookup[as.character(group)],
      group = lookup_2[as.character(group)]
    )
  dat_2
}

#Let's apply the function to the northwest, first filtering for these local authorities.
nw_post <- E_Post %>% filter(LA %in% c("E08000016",
                                       "E08000032",
                                       "E08000033",
                                       "E07000163",
                                       "E08000017",
                                       "E06000011",
                                       "E07000164",
                                       "E07000165",
                                       "E06000010",
                                       "E08000034",
                                       "E08000035",
                                       "E06000012",
                                       "E06000013",
                                       "E07000166",
                                       "E08000018",
                                       "E07000167",
                                       "E07000168",
                                       "E07000169",
                                       "E08000019",
                                       "E08000036",
                                       "E06000014"
))
nw_colony <- nw_post %>% filter(group %in% c(5,6,7,8,13,14,15,16,17,18,19,20,21,22,23,24))  %>% group_by(LA, group) %>% summarise("Mean"=mean(E_POS))


spdf_fortified_triangle <- spdf_fortified %>% 
  group_by(id) %>% 
  group_modify(~triangle(.x)) %>% 
  unite('group_2', c(id, group), remove = F) %>% 
  mutate(state = id)

# We can now merge the triangle coordinates with the energy intensity data
state_lookup <- setNames(laddf$LAD13NM, laddf$id)
full_dataset <- nw_colony %>% 
  group_by(id) %>% 
  mutate(group = c(16,12,8,4,15,11,7,3,14,10,6,2,13,9,5,1)) %>% 
  full_join(spdf_fortified_triangle, by = c('group', 'id')) %>% 
  mutate(abb = state_lookup[id])

# We will save some coordinates based on Ryedale for plotting the legend
Ryedale <- filter(spdf_fortified, id == 'E07000167') %>% 
  mutate(
    long = long+0.1,
    lat = lat-1
  )
Ryedale_boundaries <- tibble(
  x = range(Ryedale$long)[1]+seq(1, 8, 2)*(diff(range(Ryedale$long))/8),
  y = max(Ryedale$lat) + 0.1,
  yend = min(Ryedale$lat), 
  month = c('Semi-detached', 'Terraced','Flat', 'Detached')
)
Ryedale_boundaries_2 <- tibble(
  y = range(Ryedale$lat)[1]+seq(2, 5, 1)*(diff(range(Ryedale$lat))/8),
  x = max(Ryedale$long),
  xend = min(Ryedale$long) - c(0.3, 0.2, 0.3, 0.2),
  year = c("post-2000", "1973-1999","1931-1972","pre-1930s" )
)

# Let's plot the data!
p<- full_dataset %>% 
  ggplot() +
  # Plotting the hexagon legend
  geom_text(aes(x = xend-0.1, y = y, label = year),
            hjust = 1, size = 4, family = 'Montserrat',
            data = Ryedale_boundaries_2) +
  geom_text(aes(x = x, y = y+0.05, label = month),
            hjust = 1, size = 4, angle = 90+180+40, 
            family = 'Montserrat',
            data = Ryedale_boundaries) +
  geom_polygon(aes(x = long+0.1+(0.5*0.3153901), y = lat-1-(0.75*0.3714647), 
                   group = group_2,
                   fill = ifelse(!is.na(Mean), 300, NA)),
               color = 'white',
               size = 0.2,
               data = filter(full_dataset, id == 'E07000167')) +
  geom_polygon(aes( x = long, y = lat, group = group), 
               fill="transparent", color="black",
               data = Ryedale) +
  geom_segment(aes(x = x, xend = x, y = y, yend = yend),
               size = 0.3,
               data = Ryedale_boundaries) +
  geom_segment(aes(x = x, xend = xend, y = y, yend = y),
               size = 0.3,
               data = Ryedale_boundaries_2) +
  
  # Plotting the hexbin map
  geom_polygon(aes( x = long, y = lat, 
                    group = group_2,
                    fill = (Mean)),
               color = 'white',
               size = 0.2) +
  geom_polygon(aes( x = long-(0.5*0.3153901), y = lat+(0.75*0.3714647), group = group),
               fill="transparent", color="black",
               data = spdf_fortified, size= 1) +
  
  # Plotting of the state name
  geom_text(aes(x=long+0.005, y=lat-0.01, label=gsub('(.{1,10})(\\s|$)', '\\1\n', state_lookup[state]) ),
            size = 3, angle = 33, hjust=1, vjust=1, lineheight = 0.7, color = 'black', family = 'Montserrat',
            data = summarize(group_by(full_dataset, state),
                             long = mean(long),
                             lat = max(lat))) +
  
  # Plotting the title and sub-title
  geom_text(aes(x=-1.4, y=55.45, label=label),
            size = 8, color = 'black', hjust = 0.5,
            family = 'Montserrat', fontface = "bold",
            data = tibble(label = 'How energy efficiency varies with age and type of house')) +
  geom_text(aes(x=-1.4, y=y, label=label),
            size = 4.5, color = 'black', hjust = 0.5, vjust = 1,
            family = 'Montserrat',
            data = tibble(
              label = c('Energy efficiency of a a home (measured here in terms of energy intensity or energy per unit floor area) can vary',
                        'considerably with the type of house (flat, detached, or terraced housing) as well as the age of the house.',
                        'In addition to these universal differences, energy intensity can vary depending on where you are, which in ',
                        'turn reflects the underlying socio-economic landscape'),
              y = c(55.4, 55.35, 55.3 ,55.25))) +
  
  # Plotting the credits
  # geom_text(aes(x=-3, y=55.0, label=label),
  #           size = 3, color = 'black', hjust = 0,
  #           family = 'Montserrat', fontface = "bold",
  #           data = tibble(label = 'Data modelled based on\nEPC and NEED datasets')) +
  # 
  # Fixing the coordinates for the map
  #coord_map()  +
  
  # Changing the color scale
scale_fill_gradientn(colors=met.brewer("Hiroshige"),
                     name = 'Energy Intensity\nacross houses\nof given type\nand age\n(kWh/m2/year)',
                     na.value = 'white',
                     trans = 'reverse') +
  
  # Adding additional theme options
  theme_void()  +
  theme(legend.position = c(0.1, 0.15),
        legend.title = element_text(size = 10, family = 'Montserrat'),
        legend.key.size = unit(15, 'pt'),
        legend.text = element_text(size = 10, family = 'Montserrat')) #+


p + 
  labs(
    caption = "Visualization: Andre Neto-Bradley  .  Data: Modelled based on EPC and NEED datasets"
  )

