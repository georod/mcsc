#=================================================
# Multi-city structural Connectivity Project (MCSC)
#=================================================

# 2023-02-03
# This is version 5: urban_features_master_list_v5.R 
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

# Main aim: Create Urban features master list

# Note: This code should be run on a local environment that has a OSM planet file loaded in PostgreSQL (not on DRAC/CC infrastructure). 
#   Also, this code only uses features for Ontario as a template for the entire project.


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
df_unique <- df %>% dplyr::count(feature, type, material, view, .drop=FALSE)
#check 
#df_unique %>% filter(feature =="commercial_industrial")

#create summary tables - intermediate products
#df_unique_features <- df_unique %>% count(feature, priority)
#df_unique_features_types <- df_unique %>% count(feature,type, priority)

##set resistance values 
head(df_unique)


#eliminate values for background feature, since now using envelope as background
#df_unique_res  <- df_unique %>% filter(feature != 'background')


#eliminate values for background feature, since now using envelope as background
#df_unique_res  <- df_unique_res %>% filter(feature != 'background')

##check 
#check <- df_unique_res %>% count(feature, priority, res_large_mammals, res_small_mammals)
##footway in commercial_industrial
#View(check)


##set priorities to avoid conflicting resistance values within the same priority level
df_unique_res <- df_unique %>% 
  #priority values define how features are overlaid in the final map, with higher values being on top
  ##landuse background
  mutate(priority = ifelse(feature == "commercial_industrial" & type =="industrial", 1, 'NULL')) %>% #Why NULL and not NA?
  mutate(priority = ifelse(feature == "commercial_industrial" & type %in% c("commercial", "retail"), 2, priority)) %>%
  mutate(priority = ifelse(feature == "institutional", 3, priority))%>%
  mutate(priority = ifelse(feature == "residential", 4, priority))%>%
  mutate(priority = ifelse(feature == "landuse_rail", 5, priority))%>%
  ##green background
<<<<<<< HEAD
  mutate(priority = ifelse(feature == "open_green_area", 6, priority))%>%
  mutate(priority = ifelse(feature == "resourceful_green_area", 7, priority))%>%  
  mutate(priority = ifelse(feature == "hetero_green_area", 8, priority))%>%
  mutate(priority = ifelse(feature == "dense_green_area", 9, priority))%>%
=======
  mutate(priority = ifelse(feature == "open_green_area", 5, priority))%>%
  mutate(priority = ifelse(feature == "resourceful_green_area", 6, priority))%>%  
  mutate(priority = ifelse(feature == "hetero_green_area", 7, priority))%>%
  mutate(priority = ifelse(feature == "dense_green_area", 8, priority))%>%
  ##flooded surface (note includes wetlands, if wetlands want to be separated sql code should be changed)
  mutate(priority = ifelse(feature == "water", 9, priority)) 
>>>>>>> b074416de9daaf385499853886004443a456b70a
  ##built infrastructure
  mutate(priority = ifelse(feature == "parking_surface", 10, priority))%>%
  mutate(priority = ifelse(feature == "building", 11, priority))%>%
  ##roads - highways go below other linear features to allow for over and underpasses
  mutate(priority = ifelse(feature == "linear_feature_vh_traffic",12, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_na_traffic", 13, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_vl_traffic",14, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_l_traffic", 15, priority))%>%  
  mutate(priority = ifelse(feature == "linear_feature_m_traffic", 16, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_h_traffic_ls", 17, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_h_traffic_hs", 18, priority))%>%
  #trams included here
  mutate(priority = ifelse(feature == "linear_feature_rail" & type %in% c('tram'), 19, priority))%>%
  ##pedestrian roads #allows for overpasses and underpasses by being set with higher priority as roads
  mutate(priority = ifelse(feature == "linear_feature_no_traffic" & material != 'sidewalk', 20, priority))%>%
  #mutate(priority = ifelse(feature == "linear_feature_no_traffic" & material == 'sidewalk', 20, priority))%>%
  ##railways
  mutate(priority = ifelse(feature == "linear_feature_rail", 21, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail" & type %in% c('abandoned','disused','construction'), 22, priority))%>%
  ##barriers (too thin to appear on 30m resolution layer, useful for other purposes) 
  mutate(priority = ifelse(feature == "barrier", 23, priority))%>%
  ##flooded surface (note includes wetlands, if wetlands want to be separated sql code should be changed)
  mutate(priority = ifelse(feature == "water", 24, priority)) 



# If correct, there should not be resistance values equal to NA. It works.
#unique(df_unique_res[(df_unique_res$res_large_mammals=='NULL'), 2])
#unique(df_unique_res[(df_unique_res$res_small_mammals=='NULL'), 2])

#write.csv(df_unique_res, 'df_unique_res_2.csv') 
##set resistance values across layers -- this step could be bypassed by creating only the landcover layer and reclassifying the classes into the resistance values, I am creating R script for that
df_unique_res <- df_unique_res %>% 
  #resistance values define the resistance to movement of each feature
  ##landuse background
  mutate(resistance = ifelse(feature == "commercial_industrial" & type =="industrial", 70, 'NULL')) %>%
  mutate(resistance = ifelse(feature == "commercial_industrial" & type %in% c("commercial", "retail"), 50, resistance)) %>%
  mutate(resistance = ifelse(feature == "institutional", 35, resistance))%>%
  mutate(resistance = ifelse(feature == "residential", 40, resistance))%>%
  mutate(resistance = ifelse(feature == "landuse_rail", 30, resistance))%>%
  ##green background
  mutate(resistance = ifelse(feature == "open_green_area", 15, resistance))%>%
  mutate(resistance = ifelse(feature == "resourceful_green_area", 10, resistance))%>%  
  mutate(resistance = ifelse(feature == "hetero_green_area", 10, resistance))%>%
  mutate(resistance = ifelse(feature == "dense_green_area", 5, resistance))%>%
  ##flooded surface (note includes wetlands, if wetlands want to be separated sql code should be changed)
  mutate(resistance = ifelse(feature == "water", 100, resistance)) 
  ##built infrastructure
  mutate(resistance = ifelse(feature == "parking_surface", 20, resistance))%>%
  mutate(resistance = ifelse(feature == "building", 100, resistance))%>%
  ##roads - highways go below other linear features to allow for over and underpasses
  mutate(resistance = ifelse(feature == "linear_feature_vh_traffic", 80, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_na_traffic", 40, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_vl_traffic", 25, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_l_traffic", 35, resistance))%>%  
  mutate(resistance = ifelse(feature == "linear_feature_m_traffic", 40, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_h_traffic_ls", 45, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_h_traffic_hs", 50, resistance))%>%
  #trams included here
  mutate(resistance = ifelse(feature == "linear_feature_rail"& type %in% c('tram'), 45, resistance))%>%
  ##pedestrian roads #allows for overpasses and underpasses by being set with higher resistance as roads
  mutate(resistance = ifelse(feature == "linear_feature_no_traffic"& material != 'sidewalk', 15, resistance))%>%
  #mutate(resistance = ifelse(feature == "linear_feature_no_traffic"& material == 'sidewalk', 20, resistance))%>%
  ##railways
  mutate(resistance = ifelse(feature == "linear_feature_rail", 15, resistance))%>%
  mutate(resistance = ifelse(feature == "linear_feature_rail"& type %in% c('abandoned','disused','construction'), 10, resistance))%>%
  ##barriers (too thin to appear on 30m resolution layer, useful for other purposes) 
  mutate(resistance = ifelse(feature == "barrier", 70, resistance))%>%



##update resistance values for small_mammals and add them in a new column
df_unique_res  <- df_unique_res %>% 
  mutate(resistance_sm = ifelse(feature == "parking_surface", 30, resistance))%>%
  mutate(resistance_sm = ifelse(feature == "residential", 30, resistance_sm))%>%
  mutate(resistance_sm = ifelse(feature == "institutional", 30, resistance_sm))%>%
  mutate(resistance_sm = ifelse(feature == "linear_feature_vl_traffic",40, resistance_sm))%>% 
  mutate(resistance_sm = ifelse(feature == "linear_feature_l_traffic", 50, resistance_sm))%>%
  mutate(resistance_sm = ifelse(feature == "linear_feature_m_traffic", 65, resistance_sm))%>%
  mutate(resistance_sm = ifelse(feature == "linear_feature_h_traffic_ls", 70, resistance_sm))%>%
  mutate(resistance_sm = ifelse(feature == "linear_feature_h_traffic_hs", 80, resistance_sm))%>%
  mutate(resistance_sm = ifelse(feature == "linear_feature_vh_traffic", 95, resistance_sm))


#rename columns
df_unique_res  <- df_unique_res %>% rename(res_large_mammals = resistance, res_small_mammals = resistance_sm)

# Add new column "class" 
df_unique_res$class <- df_unique_res$priority

# Save object
saveRDS(df_unique_res, "../misc/df_unique_res.rds")
# Restore object
#df_unique_res <- readRDS("df_unique_res.rds")


# disconnect from db
dbDisconnect(con_pg)
