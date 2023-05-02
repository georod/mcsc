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
##set priorities to avoid conflicting resistance values within the same priority level
df_unique_res <- df_unique %>% 
  mutate(priority = case_when(
    df_unique$feature == "commercial_industrial" & !(df_unique$type %in% c("commercial", "retail")) ~ '1',
    df_unique$feature == "commercial_industrial" & df_unique$type %in% c("commercial", "retail") ~ '2',
    df_unique$feature == "institutional"  ~  '3',
    df_unique$feature == "residential"  ~  '4',
    df_unique$feature == "landuse_rail"  ~  '5',
    df_unique$feature == "open_green_area"  ~  '6',
    df_unique$feature == "protected_area"  ~  '7', 
    df_unique$feature == "resourceful_green_area"  ~  '8',
    df_unique$feature == "hetero_green_area"  ~  '9', #non_bare_soil
    df_unique$feature == "bare_soil"  ~   '10' , #bare_soil
    df_unique$feature == "dense_green_area"  ~   '11',
    df_unique$feature == "water"  ~   '12', 
    df_unique$feature == "waterways"  ~   '12', ### hope this wont create trouble, they are both supposed to be at the same level
    df_unique$feature == "parking_surface"  ~ '13',
    df_unique$feature == "building"  ~  '14',
    df_unique$feature == "linear_feature_vh_traffic"  ~  '15',
    df_unique$feature == "linear_feature_no_traffic" & df_unique$material == 'sidewalk'  ~  '16', # sidewalks
    df_unique$feature == "linear_feature_na_traffic"  ~   '17',
    df_unique$feature == "linear_feature_vl_traffic"  ~  '18',
    df_unique$feature == "linear_feature_l_traffic"  ~  '19',
    df_unique$feature == "linear_feature_m_traffic"  ~  '20',
    df_unique$feature == "linear_feature_h_traffic_ls"  ~  '21',
    df_unique$feature == "linear_feature_h_traffic_hs"  ~  '22',
    df_unique$feature == "linear_feature_rail" & df_unique$type == 'tram'  ~  '23', # tram_lines
    df_unique$feature == "linear_feature_no_traffic" & !(df_unique$material %in% c('sidewalk'))  ~  '24', # except sidewalks
    df_unique$feature == "linear_feature_rail" & !(df_unique$type %in% c('tram','abandoned','disused','construction'))
                                                   & !(df_unique$material %in% c('construction')) ~  '25',
    df_unique$feature == "linear_feature_rail" & 
      (df_unique$type %in% c('abandoned','disused','construction') | df_unique$material == 'construction')  ~  '26',
    df_unique$feature == "barrier"  ~  '27'))


#View(df_unique_res)
df_unique_res$priority<-as.numeric(df_unique_res$priority)
priority_table <- df_unique_res %>% dplyr::count(priority, feature, .drop=FALSE)
df_unique_res%>% filter(feature == "linear_feature_no_traffic" & is.na(priority))

write.csv(df_unique_res, 'df_unique_res.csv')


# Save object
saveRDS(df_unique_res, "../misc/df_unique_res.rds")
# Restore object
#df_unique_res <- readRDS("df_unique_res.rds")


# disconnect from db
dbDisconnect(con_pg)
