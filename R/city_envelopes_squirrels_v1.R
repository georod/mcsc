#============================================
# Multi-city structural Connectivity Project
#============================================

# 2023-12-01
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

# Main aim: Create city envelopes to be used as study areas for Tiziana's Squirrel project


#===============================
# Load libraries
#===============================

start.time <- Sys.time()

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
#setwd("C:/Users/Peter R/github/mcsc/")

# project output folder
outF <- "projects/def-mfortin/georod/data/mcsc-proj/"

city <- read.csv("./misc/mcsc_city_list_squirrels.csv")

#=================================
# Connect to PG db
#=================================
# add username and pwd to .Renviron
# local machine
# con_pg <- DBI::dbConnect(
#   drv = RPostgres::Postgres(),
#   host = "localhost",
#   port = 5432,
#   dbname = "osm_ont",
#   #dbname = "georod_db_osm",
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
#city <- city[!(city$pg_city %in% c('Toronto', 'Chicago', 'City_of_New_York', 'Fort_Collins')),]
#city <- city[(city$pg_city %in% c('Peterborough')),]
#city <- city[(city$pg_city %in% c('Toronto')),]
#city <- city[(city$pg_city %in% c('Toronto', 'Peterborough')),]
#city <- city[(city$pg_city %in% c('Victoria')),]
#city <- city[(city$pg_city %in% c('Jackson')),]
#city <- city[(city$pg_city %in% c('Key_Largo')),]
#city <- city[(city$pg_city %in% c('Golden_Horseshoe')),]
#print(city)

# Loop for creating city spatial envelopes


for (j in 1:nrow(city)) {
  
  dbSendQuery(con_pg, paste0("DROP TABLE IF EXISTS ", city$pg_city[j],"_env", " CASCADE;"))
  
  #dbSendQuery(con_pg, paste0("CREATE TABLE ", city$pg_city[j],"_env", "  AS SELECT (row_number() OVER ())::int AS sid, relation_id::varchar(20), 'background'::varchar(30) AS feature, tags->>'name'::varchar(30)  AS type, tags ->> 'admin_level'::varchar(30) AS material, '' AS size, st_envelope(st_buffer(st_envelope(st_multi(st_buildarea(geom))), 500))::geometry(Polygon, 3857) AS geom  FROM boundaries WHERE tags->> 'boundary' IN ('administrative') AND tags->> 'name'=","'", city$osm_city[j],"'" , " AND tags ->> 'admin_level'=","'",city$admin_level[j], "';"))
  dbSendQuery(con_pg, paste0("CREATE TABLE ", city$pg_city[j],"_env", "  AS SELECT (row_number() OVER ())::int AS sid, relation_id::varchar(20), 'background'::varchar(30) AS feature, tags->>'name'::varchar(30)  AS type, tags ->> 'admin_level'::varchar(30) AS material, '' AS size, st_envelope(st_buffer(st_envelope(st_multi(st_buildarea(geom))),", city$buffer[j]*1000, "))::geometry(Polygon, 3857) AS geom  FROM boundaries WHERE relation_id=", city$osm_id[j], " ;"))
  
  dbSendQuery(con_pg, paste0("ALTER TABLE ", city$pg_city[j],"_env", " ADD CONSTRAINT ", city$pg_city[j],"_env", "_pkey PRIMARY KEY (sid);"))
  
  dbSendQuery(con_pg, paste0("CREATE INDEX ", city$pg_city[j],"_env", "_geom_idx ON ", city$pg_city[j],"_env",  " USING gist (geom) WITH (FILLFACTOR=100);") )

  print(city$pg_city[j])
}
  


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

# disconnect from db
dbDisconnect(con_pg)



