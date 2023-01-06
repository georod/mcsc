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
#library(RPostgreSQL)
#library("RPostgres") 

library(sf)
library(terra)


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


#start.time <- Sys.time()

#====================================
# Create city urban features vectors
#====================================

# List of city names found in OSM (OpenStreetMap)
city <- c('Peterborough', 'Brantford') # 'Brantford'


# Loop for creating city spatial envelopes

for (j in 1:length(city)) {
  
  
  dbSendQuery(con_pg, paste0("DROP TABLE IF EXISTS ", city[j],"_env", " CASCADE;"))
  
  dbSendQuery (con_pg, paste0("CREATE TABLE ",city[j],"_env", " AS SELECT sid, st_envelope(st_buffer(geom, 500))::geometry('Polygon', 3857) AS geom FROM background_layer3
                   where type =" ,"'", city[j], "'", " and material='6'"))
  
  dbSendQuery(con_pg, paste0("ALTER TABLE ", city[j],"_env", " ADD CONSTRAINT ", city[j],"_env", "_pkey PRIMARY KEY (sid);"))
  
  dbSendQuery(con_pg, paste0("CREATE INDEX ",city[j],"_env", "_geom_idx ON ", city[j],"_env",  " USING gist (geom) WITH (FILLFACTOR=100) TABLESPACE pg_default;") )
  
}


#end.time <- Sys.time()
#time.taken <- end.time - start.time
#time.taken

# disconnect from db
dbDisconnect(con_pg)


