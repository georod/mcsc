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
df_unique <- df %>% dplyr::count(feature, type, material, size, view, .drop=FALSE)
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
  mutate(priority = ifelse(feature == "commercial_industrial" & (type %in% c("industrial", "fairground") | size == "factory"), 1, 'NULL')) %>% #Why NULL and not NA?
  mutate(priority = ifelse(feature == "commercial_industrial" & type %in% c("commercial", "retail"), 2, priority)) %>%
  mutate(priority = ifelse(feature == "institutional", 3, priority))%>%
  mutate(priority = ifelse(feature == "residential", 4, priority))%>%
  mutate(priority = ifelse(feature == "landuse_rail", 5, priority))%>%
  ##green background, now includes protected areas as a layer to account those protected areas where vegetation is not described (this could be superceded by the CEC landcover
  mutate(priority = ifelse(feature == "open_green_area", 6, priority))%>%
  mutate(priority = ifelse(feature == "protected_area", 7, priority))%>%  
  mutate(priority = ifelse(feature == "resourceful_green_area", 8, priority))%>%  
  mutate(priority = ifelse(feature == "hetero_green_area" & !(material %in% c('sand','scree','sinkhole', 'beach') | 
                                                             type %in% c('brownfield', 'construction') | 
                                                             size %in% c('bunker')), 9, priority)) %>%
  ##bare non-vegetated-non-concrete layer
  mutate(priority = ifelse(feature == "hetero_green_area" & (material %in% c('sand','scree','sinkhole', 'beach') | 
                                                             type %in% c('brownfield', 'construction') | 
                                                             size %in% c('bunker')), 10 , priority))%>%

  mutate(priority = ifelse(feature == "dense_green_area", 11, priority))%>%
  ##water, does not include temporary retention basins
  mutate(priority = ifelse(feature == "water", 12, priority))%>% 
  ##built infrastructure
  mutate(priority = ifelse(feature == "parking_surface", 13, priority))%>%
  mutate(priority = ifelse(feature == "building", 14, priority))%>%
  ##roads - highways go below other linear features to allow for over and underpasses
  mutate(priority = ifelse(feature == "linear_feature_vh_traffic",15, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_no_traffic" & material == 'sidewalk', 16, priority))%>% ### sidewalks.
  mutate(priority = ifelse(feature == "linear_feature_na_traffic", 17, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_vl_traffic",18, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_l_traffic", 19, priority))%>%  
  mutate(priority = ifelse(feature == "linear_feature_m_traffic", 20, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_h_traffic_ls", 21, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_h_traffic_hs", 22, priority))%>%
  #trams included here
  mutate(priority = ifelse(feature == "linear_feature_rail" & type == 'tram', 23, priority))%>% ## this layer did not appear, should debug code
  ##pedestrian roads #allows for overpasses and underpasses by being set with higher priority as roads
  mutate(priority = ifelse(feature == "linear_feature_no_traffic" & material != 'sidewalk', 24, priority))%>% ### sidewalks.

  #mutate(priority = ifelse(feature == "linear_feature_no_traffic" & material == 'sidewalk', 20, priority))%>%
  ##railways
  mutate(priority = ifelse(feature == "linear_feature_rail", 25, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail" & (type %in% c('abandoned','disused','construction') | material == 'construction'), 26, priority))%>%
  ##barriers (too thin to appear on 30m resolution layer, useful for other purposes) 
  mutate(priority = ifelse(feature == "barrier", 27, priority)) ## the



# Add new column "class" 
df_unique_res$class <- df_unique_res$priority

# Save object
saveRDS(df_unique_res, "../misc/df_unique_res.rds")
# Restore object
#df_unique_res <- readRDS("df_unique_res.rds")


# disconnect from db
dbDisconnect(con_pg)
