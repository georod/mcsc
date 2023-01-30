#=================================================
# Multicity structural Connectivity Project (MCSC)
#=================================================

# 2023-01-23
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

# Main aim: Create Urban features master list


#===================
# Libraries
#===================
library(DBI)
# Using dplyr
#install.packages("dplyr")
library(dplyr)
#install.packages('vctrs')
#library(vctrs)

#sessionInfo()

#detach("dplyr", unload=TRUE)

#=================================
# Connect to PG db
#=================================
# add username and pwd to .Renviron
con_pg <- DBI::dbConnect(
  drv = RPostgres::Postgres(),
  host = "localhost",
  port = 5432,
  dbname = "osm",
  user = Sys.getenv("username"),
  password = Sys.getenv("pwd")
)


#=================================
# Create features list
#=================================
df <- dbGetQuery(con_pg, "SELECT distinct * FROM urban_features_v1")
dim(df)

##create able with unique values
df_unique <- df %>% dplyr::count(feature, type, material, priority, view, .drop=FALSE)
#check 
#df_unique %>% filter(feature =="commercial_industrial")

#create summary tables - intermediate products
df_unique_features <- df_unique %>% count(feature, priority)
df_unique_features_types <- df_unique %>% count(feature,type, priority)

##set resistance values 
head(df_unique)
df_unique_res <- df_unique %>% 
  mutate(resistance = ifelse(feature == "background", 50, 'NULL')) %>%
  mutate(resistance = ifelse(feature == "water", 100, resistance)) %>%
  mutate(resistance = ifelse(feature == "barrier", 70, resistance))%>%
  mutate(resistance = ifelse(feature == "parking_surface", 20, resistance))%>%
  mutate(resistance = ifelse(feature == "residential", 35, resistance))%>%
  mutate(resistance = ifelse(feature == "institutional", 30, resistance))%>%
  mutate(resistance = ifelse(feature == "open_green_area", 20, resistance))%>%
  mutate(resistance = ifelse(feature == "hetero_green_area", 10, resistance))%>%
  mutate(resistance = ifelse(feature == "dense_green_area", 5, resistance))%>%
  mutate(resistance = ifelse(feature == "resourceful_green_area", 10, resistance))%>%
  mutate(resistance = ifelse(feature == "building", 100, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_rail", 15, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_rail"& type %in% c('abandoned','disused','miniature','proposed','razed','signal_box'), 10, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_rail"& type %in% c('light_rail','narrow_gauge','proposed','rail','turntable'), 20, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_rail"& type %in% c('platform'), 30, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_rail"& type %in% c('tram'), 45, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_rail"& type %in% c('construction'), 50, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_rail"& type %in% c('preserved','station','traverser'), 100, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature", 20, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature"& type %in% c('abandoned','footway','proposed','razed'), 10, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature"& type %in% c('bridleway','construction','crossing','path','pedestrian','proposed','rest_area','services','track'), 20, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature"& type %in% c('cycleway','living_street','platform','residential','steps'), 30, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature"& type %in% c('primary','road','secondary','secondary_link','tertiary','tertiary_link','unclassified'), 45, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature"& type %in% c('construction','escape','motorway','motorway_link','trunk','trunk_link','turning_loop'), 50, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature"& type %in% c('corridor','elevator','platform','raceway'), 100, resistance))%>%
  mutate(resistance = ifelse(feature == "commercial_industrial" & type =="commercial", 50, resistance)) %>%
  mutate(resistance = ifelse(feature == "commercial_industrial" & type =="retail", 50, resistance)) %>%
  mutate(resistance = ifelse(feature == "commercial_industrial" & type =="industrial", 70, resistance))
#df_unique %>% filter(feature=="commercial_industrial")

##update resistance values for small_mammals and add them in a new column
df_unique_res  <- df_unique_res %>% 
  mutate(resistance_sm = ifelse(feature == "linear_feature", 40, resistance)) 

#rename columns
df_unique_res  <- df_unique_res %>% rename(res_large_mammals = resistance, res_small_mammals = resistance_sm)

#eliminate values for background feature, since now using envelope as background
df_unique_res  <- df_unique_res %>% filter(feature != 'background')

##check 
#check <- df_unique_res %>% count(feature, priority, res_large_mammals, res_small_mammals)
##footway in commercial_industrial
#View(check)


##set priorities to avoid conflicting resistance values within the same priority level
df_unique_res <- df_unique_res %>% 
  #mutate(priority = ifelse(feature == "background", 'NULL', 'NULL')) %>%
  mutate(priority = ifelse(feature == "water", 26, priority)) %>%
  mutate(priority = ifelse(feature == "barrier", 25, priority))%>%
  mutate(priority = ifelse(feature == "parking_surface", 9, priority))%>%
  mutate(priority = ifelse(feature == "residential", 4, priority))%>%
  mutate(priority = ifelse(feature == "institutional", 3, priority))%>%
  mutate(priority = ifelse(feature == "open_green_area", 6, priority))%>%
  mutate(priority = ifelse(feature == "hetero_green_area", 7, priority))%>%
  mutate(priority = ifelse(feature == "dense_green_area", 8, priority))%>%
  mutate(priority = ifelse(feature == "resourceful_green_area", 5, priority))%>%
  mutate(priority = ifelse(feature == "building", 10, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail", 18, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail"& type %in% c('abandoned','disused','miniature','proposed','razed','signal_box'), 19, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail"& type %in% c('light_rail','narrow_gauge','proposed','rail','turntable'), 20, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail"& type %in% c('platform'), 21, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail"& type %in% c('tram'), 22, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail"& type %in% c('construction'), 23, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail"& type %in% c('preserved','station','traverser'), 24, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature", 11, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature"& type %in% c('abandoned','footway','proposed','razed'), 12, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature"& type %in% c('bridleway','construction','crossing','path','pedestrian','proposed','rest_area','services','track'), 13, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature"& type %in% c('cycleway','living_street','platform','residential','steps'), 14, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature"& type %in% c('primary','road','secondary','secondary_link','tertiary','tertiary_link','unclassified'), 15, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature"& type %in% c('construction','escape','motorway','motorway_link','trunk','trunk_link','turning_loop'), 16, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature"& type %in% c('corridor','elevator','platform','raceway'), 17, priority))%>%
  mutate(priority = ifelse(feature == "commercial_industrial" & type =="commercial", 2, priority)) %>%
  mutate(priority = ifelse(feature == "commercial_industrial" & type =="retail", 2, priority)) %>%
  mutate(priority = ifelse(feature == "commercial_industrial" & type =="industrial", 1, priority))

df_unique_res$class <- df_unique_res$priority

df_unique_res <- df_unique_res %>% 
  #mutate(class = ifelse(feature == "background", 'NULL', 'NULL')) %>%
  mutate(class = ifelse(feature == "water", 26, class)) %>%
  mutate(class = ifelse(feature == "barrier", 25, class))%>%
  mutate(class = ifelse(feature == "parking_surface", 9, class))%>%
  mutate(class = ifelse(feature == "residential", 4, class))%>%
  mutate(class = ifelse(feature == "institutional", 3, class))%>%
  mutate(class = ifelse(feature == "open_green_area", 6, class))%>%
  mutate(class = ifelse(feature == "hetero_green_area", 7, class))%>%
  mutate(class = ifelse(feature == "dense_green_area", 8, class))%>%
  mutate(class = ifelse(feature == "resourceful_green_area", 5, class))%>%
  mutate(class = ifelse(feature == "building", 10, class))%>%
  mutate(class = ifelse(feature == "linear_feature_rail", 18, class))%>%
  mutate(class = ifelse(feature == "linear_feature_rail"& type %in% c('abandoned','disused','miniature','proposed','razed','signal_box'), 19, class))%>%
  mutate(class = ifelse(feature == "linear_feature_rail"& type %in% c('light_rail','narrow_gauge','proposed','rail','turntable'), 20, class))%>%
  mutate(class = ifelse(feature == "linear_feature_rail"& type %in% c('platform'), 21, class))%>%
  mutate(class = ifelse(feature == "linear_feature_rail"& type %in% c('tram'), 22, class))%>%
  mutate(class = ifelse(feature == "linear_feature_rail"& type %in% c('construction'), 23, class))%>%
  mutate(class = ifelse(feature == "linear_feature_rail"& type %in% c('preserved','station','traverser'), 24, class))%>%
  mutate(class = ifelse(feature == "linear_feature", 11, class))%>%
  mutate(class = ifelse(feature == "linear_feature"& type %in% c('abandoned','footway','proposed','razed'), 12, class))%>%
  mutate(class = ifelse(feature == "linear_feature"& type %in% c('bridleway','construction','crossing','path','pedestrian','proposed','rest_area','services','track'), 13, class))%>%
  mutate(class = ifelse(feature == "linear_feature"& type %in% c('cycleway','living_street','platform','residential','steps'), 14, class))%>%
  mutate(class = ifelse(feature == "linear_feature"& type %in% c('primary','road','secondary','secondary_link','tertiary','tertiary_link','unclassified'), 15, class))%>%
  mutate(class = ifelse(feature == "linear_feature"& type %in% c('construction','escape','motorway','motorway_link','trunk','trunk_link','turning_loop'), 16, class))%>%
  mutate(class = ifelse(feature == "linear_feature"& type %in% c('corridor','elevator','platform','raceway'), 17, class))%>%
  mutate(class = ifelse(feature == "commercial_industrial" & type =="commercial", 2, class)) %>%
  mutate(class = ifelse(feature == "commercial_industrial" & type =="retail", 2, class)) %>%
  mutate(class = ifelse(feature == "commercial_industrial" & type =="industrial", 1, class))

 #write.csv(df_unique_res, 'df_unique_res_2.csv') 


# Save object
saveRDS(df_unique_res, "df_unique_res.rds")
# Restore object
#df_unique_res <- readRDS("df_unique_res.rds")


# disconnect from db
dbDisconnect(con_pg)
