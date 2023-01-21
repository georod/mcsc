#============================================
# Multi-city structural Connectivity Project
#============================================

# 2022-12-19
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

# Main aim: Create city envelopes to be used as study areas


#===============================
# Load libraries
#===============================


#install.packages("RPostgres") # This needs to be installed but may not be loaded

library(DBI)
#library(dplyr)
#library("RPostgres") 

library(sf)
library(terra)

#=================================
# Set folder & files paths
#=================================

# github project folder on server
setwd("~/projects/def-mfortin/georod/scripts/mcsc/")
# project folder on desktop
#setwd("~/github/mcsc/")

# project output folder
outF <- "projects/def-mfortin/georod/data/mcsc-proj/"

city <- read.csv("./misc/mcsc_city_list1.csv")

#=================================
# Connect to PG db
#=================================
# add username and pwd to .Renviron
# local machine
# con_pg <- DBI::dbConnect(
#   drv = RPostgres::Postgres(),
#   host = "localhost",
#   port = 5432,
#   #dbname = "osm",
#   dbname = "georod_db_osm",
#   user = Sys.getenv("username"),
#   password = Sys.getenv("pwd")
# )

# Remote server. Thsi assumes this R script is running within the server
con_pg <- DBI::dbConnect(
  drv = RPostgres::Postgres(),
  host = "cedar-pgsql-vm",
  port = 5432,
  dbname = "georod_db_osm"
)


#start.time <- Sys.time()

#====================================
# Create city urban features vectors
#====================================

# List of city names found in OSM (OpenStreetMap)
#city <- c('Peterborough', 'Brantford') # 'Brantford'
city <- city[!is.na(city$osm_id),]
city$pg_city <- gsub(" ", "_", city$osm_city)
city <- city[city$pg_city=='Toronto',]

# Loop for creating city spatial envelopes


for (j in 1:nrow(city)) {
  
  dbSendQuery(con_pg, paste0("DROP TABLE IF EXISTS ", city$pg_city[j],"_env", " CASCADE;"))
  
   
  dbSendQuery(con_pg, paste0("ALTER TABLE ", city$pg_city[j],"_env", " ADD CONSTRAINT ", city$pg_city[j],"_env", "_pkey PRIMARY KEY (sid);"))
  
  dbSendQuery(con_pg, paste0("CREATE INDEX ", city$pg_city[j],"_env", "_geom_idx ON ", city$pg_city[j],"_env",  " USING gist (geom) WITH (FILLFACTOR=100) TABLESPACE pg_default;") )

  
}
  


#end.time <- Sys.time()
#time.taken <- end.time - start.time
#time.taken

# disconnect from db
dbDisconnect(con_pg)


