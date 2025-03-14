#============================================
# Multi-city structural Connectivity Project
#============================================

# 2023-07-11
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

#  Main aim: convert OSM & CEC land cover tp new land cover raster
#  Note: 2023-06-20 - this R script was called C:\Users\Peter R\github\mcsc\R\features_to_lcover_v4.R
#  Note: this version does not use dplyr as it seems to be causing conflicts on DRAC

start.time <- Sys.time()
start.time

#===================
# Libraries
#===================

#sessionInfo()
library(DBI)
#library(RPostgreSQL)
library(sf)
library(terra)
#install.packages("sqldf")
library(sqldf)
#library(dplyr)



#==================================
# Set folder & files paths - STEP 1
#==================================
# github project folder on server
setwd("~/projects/def-mfortin/georod/scripts/mcsc/")
# project folder on desktop
#setwd("~/github/mcsc/")
#setwd("C:/Users/Peter R/github/mcsc")
##Tiziana's working directory for this project
#setwd("C:/Users/tizge/Documents/StructuralconnectivityDB/")

# project output folder
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/test6/peter_newcode/"
#project output on server
#outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/smallmam/"

## loop creates both resistance maps anyways
outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/mammals/"

##Tiziana's output folder for this project'
#outF <- "C:/Users/tizge/Documents/StructuralconnectivityDB/df2/"
#outF <- "C:/Users/Peter R/Documents/mcsc_proj/df2"


#===============================
# files needed to run this - STEP 1
#================================

# table with all the views we create with PG admin
view_table <- read.csv('./misc/reference_all_views.csv', header=TRUE)

# list of cities with OSM ID
#city <- read.csv("./misc/mcsc_city_list_squirrels.csv")
city <- read.csv("./misc/mcsc_city_list1.csv")


#=================================
# Connect to PG db - STEP 2
#=================================
# add username and pwd to .Renviron
# PR's local database
# con_pg <- DBI::dbConnect(
# drv = RPostgres::Postgres(),
# host = "localhost",
# port = 5432,
# dbname = "osm_ont",
# user = Sys.getenv("username"),
# password = Sys.getenv("pwd")
# )


# Remote server. Thsi assumes this R script is running within the server
con_pg <- DBI::dbConnect(
  drv = RPostgres::Postgres(),
  host = "cedar-pgsql-vm",
  port = 5432,
  dbname = "georod_db_osm"
)


##Tiziana's db
# con_pg <- DBI::dbConnect(
#   drv = RPostgres::Postgres(),
#   host = "localhost",
#   port = 5432,
#   dbname = "osm",
#   user = "postgres",
#   password = "***")
# # 



#=========================================================
# Create city vector - STEP 3
#=========================================================

city <- city[!is.na(city$osm_id),]
city$pg_city <- gsub(" ", "_", city$osm_city)

#city <- city[(city$pg_city %in% c('Peterborough')),6]
#city <- city[(city$pg_city %in% c('Toronto')), 6]

#city <- city$pg_city[-c(20,23,24)] # Removing Peterborough, Toronto, & Syracuse

#city <- city[c(1:4), 6] # Skip Freiburg, no Germany OSM on DRAC
#city <- city[c(6:10),6]
#city <- city[c(11:13),6] # I ran out of memory and code stopped at National_Capital_Area.  Did complete, osm lyr not created.
#city <- city[c(14),6] # I was able to run the National Capital using 120GB of RAM and 5 hours
#city <- city[c(15:18),6] # did complete, osm lyr not created.
#city <- city[c(19),6] # New york needs more memory. I gave it 60GB & 3 hours. It completed successfully.
#city <- city[c(20:22, 24, 25 ),6] # Skip Toronto, already done
#city <- city[c(26:29),6] 
#city <- city[c(30),6] # San Diego is big too. Run alone
#city <- city[c(31),6] # Aromas does not exist in DRAC's OSM. Skipping for now
#city <- city[c(32:34),6] #
#city <- city[c(35:nrow(city)),6] # Now I have permission on public schema and can run Victoria
#city <- city[c(36),6] # Jackson. manually ran
#city <- city[c(37),6] # Key Largo
#city <- city[c(38),6] # Golden Horseshoe
#city <- city[c(12),6] # Chicago

# version 9 using features_union_string_v2.R.
#city <- city[c(1:4,6:13, 15:18),6] # Skip Freiburg, National Capital
#city <- city[c(20:29, 32:37),6] # Skip Aromas does not exist in DRAC's OSM.
#city <- city[c(14),6] # I was able to run the National Capital using 120GB of RAM and 5 hours
#city <- city[c(19),6] # New york needs more memory. I gave it 60GB & 3 hours. It completed successfully.
#city <- city[c(30),6] # San Diego is big too. Run alone
#city <- city[c(38),6] # Golden Horseshoe
#city <- city[c(39:40),6] # Seattle, San Francisco
city <- city[c(41),6] # Indianapolis
#city <- city[c(42),6] # Berkeley2

pg_views1 <- unique(view_table$view)



#===============================================================================
# Generate raster for each layer of each city following priority values - STEP 4
#===============================================================================

#k <- 1

for (k in 1:length(city)) {
  
  
  #-----------------------------------
  # Create city-specific urban features
  #-----------------------------------
  
  
  city0 <- paste0(city[k],"_env")
  
  # Run features_union_string to get object pg_union_views0
  
  #pg_union_views0 <- paste(readLines("./sql/features_union_string.txt"), collapse="\n")
  #pg_union_views0 <- source("./R/features_union_string.R")
  source("./R/features_union_string_v2.R") # 2023-12-11 We added bridge<>'yes'
  #source("./R/features_union_string_parking.r")
    
  
  dfSf <- terra::vect(sf::st_read(con_pg, query=pg_union_views0))
  #str(dfSf)
  
  df <- as.data.frame(dfSf, row.names=NULL, optional=FALSE, geom=NULL)
  
  
  #print("union part done")
  
  #----------------------------------
  # Create city specific priority df
  #----------------------------------
  
  ##create table with priority values
  #df_unique2 <- df %>% dplyr::count(feature, type, material, size, view, .drop=FALSE)
  
  df_unique <- sqldf("SELECT feature, type, material, size, view, count(*) as count FROM df GROUP BY feature, type, material, size, view")
  
  ##set priorities to avoid conflicting resistance values within the same priority level
  ##PR: will we have trouble with waterways set as the same priority as water, maybe we can directly union them in PG as one single view. I added a trick to solve this for now
  df_unique[which(grepl("homeowner's", df_unique$type, fixed=TRUE)),2] <- "homeowners_association" #PR: We do need this line.
  
# Further refinement of proiority values if/when needed. Easier to modify here than in the PG sql script
  df_unique_res <- sqldf("SELECT feature,
                            	CASE		
                                  WHEN feature  =  'industrial' THEN 1
                                  WHEN feature  =  'commercial' THEN 2
                                  WHEN feature  =  'institutional' THEN 3
                                  WHEN feature  =  'residential' THEN 4
                                  WHEN feature  =  'landuse_rail' THEN 5
                                  WHEN feature  =  'open_green_area' THEN 6
                                  WHEN feature  =  'protected_area' THEN 7
                                  WHEN feature  =  'resourceful_green_area' THEN 8
                                  WHEN feature  =  'hetero_green_area' THEN 9
                                  WHEN feature  =  'bare_soil' THEN 10
                                  WHEN feature  =  'dense_green_area' THEN 11
                                  WHEN feature  =  'water' THEN 12 
                                  WHEN feature  =  'waterways' THEN 12
                                  WHEN feature  =  'parking_surface' THEN 13
                                  WHEN feature  =  'building' THEN 14
                                  WHEN feature  =  'linear_feature_vh_traffic' THEN  15
                                  WHEN feature  =  'linear_feature_no_traffic_side' THEN  16 
                                  WHEN feature  =  'linear_feature_na_traffic' THEN   17
                                  WHEN feature  =  'linear_feature_vl_traffic' THEN  18
                                  WHEN feature  =  'linear_feature_l_traffic' THEN  19
                                  WHEN feature  =  'linear_feature_m_traffic' THEN  20
                                  WHEN feature  =  'linear_feature_h_traffic_ls' THEN  21
                                  WHEN feature  =  'linear_feature_h_traffic_hs' THEN  22
                                  WHEN feature  =  'linear_feature_rail_trams' THEN  23 
                                  WHEN feature  =  'linear_feature_no_traffic' THEN  24 
                                  WHEN feature  =  'linear_feature_rail' THEN  25
                                  WHEN feature  =  'linear_feature_rail_abandoned' THEN  26
                                  WHEN feature  =  'barrier'  THEN  27
                            	END AS priority, type, material, size, view
                            	FROM df_unique")
  
  df_unique_res$class <- df_unique_res$priority # Priority & class are the same
  #View(df_unique_res)
  #df_unique_res$priority <- as.numeric(df_unique_res$priority)
  
 
  df1 <- df_unique_res[,c('feature', 'type', 'view', 'priority')]
  #priority_table_red$priority <- as.numeric(priority_table_red$priority)
  # remove duplicates 
  df1 <- df1[!duplicated(df1), ]
  
  df1 <- df1[!is.na(df1$priority),]
  
  
  df2 <- df1[,c("feature", "type", "view", "priority")] # We should call this df2 obj something else to avoid confusion
  #head(df2)
  
  df2$type <- ifelse(is.na(df2$type), 'NULL', df2$type)
  
  featUrb <- unique(df1$view)
  #head(featUrb)
  
  
  # ------------------------------------------------------------
  # Query individual layers in PG OSM database to create rasters
  
  for (i in 1:length(featUrb)) {
    
    vals <- sqldf::sqldf(paste0("SELECT distinct priority FROM df2 WHERE view='", featUrb[i],"' ORDER BY priority;"))
    
    for (j in 1:nrow(vals)) {
      
      #sqlPrimer <- sqldf::sqldf(paste0("SELECT distinct feature, type, priority, view FROM df2 WHERE view='", featUrb[i],"' AND priority=", vals$priority[j], " ;"))
      
      sqlPrimer <- sqldf::sqldf(paste0("SELECT distinct feature, CASE WHEN type is null then 'NULL' ELSE type END AS type, priority, view FROM df2 WHERE view='", featUrb[i],"' AND priority=", vals$priority[j], " ;"))
      
      
      dfSf$type <- ifelse(is.na(dfSf$type), 'NULL', dfSf$type)
      
      vectorUrFts <- dfSf[which(dfSf$view==sqlPrimer$view[1] & dfSf$type %in% sqlPrimer$type),]
      vectorUrFts$class <- sqlPrimer$priority[1]
      
      queryEnv <- paste0("SELECT * FROM ",city[k],"_env", ";")
      vectorEnv <- terra::vect(sf::st_read(con_pg, query=queryEnv))
      
      raster1 <- terra::rast(vectorEnv, resolution=30, crs="EPSG:3857")
	  
	    print(paste("done feature", featUrb[i]))
      
     
      if(length(vectorUrFts)==0)
      { print("empty vector")} else
        
      {
        rasterRes1 <- terra::rasterize(vectorUrFts, raster1, field="class", background=NA, touches=FALSE,
                                update=FALSE, cover=FALSE, overwrite=FALSE)
        
        dir.create(paste0(outF,"lcrasters"))
        dir.create(paste0(outF,"lcrasters/",city[k]))
        
        terra::writeRaster(rasterRes1, paste0(outF,"lcrasters/",city[k],"/",sqlPrimer$view[1],"__",sqlPrimer$priority[1],"__",sqlPrimer$priority[1],".tif"), overwrite=TRUE)
        
      }
      
    }
    
  }
  
  
}




# disconnect from db
dbDisconnect(con_pg)

#print("done individual raster layers")

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken


#=========================
# Stack & collapse rasters
#=========================

for (k in 1:length(city)) {
  # Read raster based on priority flag first, then stack, and collapse
  
  rasterFiles <- list.files(paste0(outF,"lcrasters/",city[k]), pattern='.tif$', full.names = TRUE)
  
  resVals <- sapply(strsplit(rasterFiles, "__"), "[", 3)
  resVals <- gsub(".tif", "", resVals)
  #resVals <- as.integer(resVals)
  
  priVals <- sapply(strsplit(rasterFiles, "__"), "[", 2)
  
  priOrd <- as.data.frame(cbind(rasterFiles, priVals, resVals))
  priOrd$priority <- as.numeric(priOrd$priVals)
  priOrd$resistance <- as.numeric(priOrd$resVals)
  priOrd <- priOrd[order(-priOrd$priority),] #reverse order
  priOrd$order <- 1:nrow(priOrd)
  
  r1 <- terra::rast(priOrd$rasterFiles)
  
  r3 <- terra::app(r1, fun='first', na.rm=TRUE)
  
  
  dir.create(paste0(outF,"lcrasters/",city[k],"/output"))
  terra::writeRaster(r3, paste0(outF,"lcrasters/",city[k],"/output/",'osm_lcover.tif'), overwrite=TRUE)
  
}


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken


# disconnect from db
dbDisconnect(con_pg)

