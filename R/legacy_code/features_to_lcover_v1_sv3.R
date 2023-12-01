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
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/test5/"
#project output on server
#outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/smallmam/"

## loop creates both resistance maps anyways
outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/mammals/"

##Tiziana's output folder for this project'
#outF <- "C:/Users/tizge/Documents/StructuralconnectivityDB/largemam/"
#outF <- "C:/Users/Peter R/Documents/mcsc_proj/largemam"


#===============================
# files needed to run this - STEP 1
#================================

# table with all the views we create with PG admin
view_table <- read.csv('./misc/reference_all_views.csv', header=TRUE)

# list of cities with OSM ID
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
# dbname = "osm",
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
city <- city[(city$pg_city %in% c('Toronto')), 6]

#city <- city$pg_city[-c(20,23,24)] # Removing Peterborough, Toronto, & Syracuse


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
  pg_union_views0 <- source("./R/features_union_string.R")
    
  
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
  
  df_unique_res$class <- df_unique_res$priority
  #View(df_unique_res)
  #df_unique_res$priority <- as.numeric(df_unique_res$priority)
  
 
  df1 <- df_unique_res[,c('feature', 'type', 'view', 'priority')]
  #priority_table_red$priority <- as.numeric(priority_table_red$priority)
  # remove duplicates 
  df1 <- df1[!duplicated(df1), ]
  
  #add resistance values in the priority_Table
  #df1 <- left_join(df1, priority_table_red, by='priority')
  
  # PR: this seems to not be needed as we are dropping t2. columns further down.
  #df1 <- sqldf("SELECT t1.*, t2.res_LM, t2.res_SM, t2.source_strength FROM df1 t1 LEFT JOIN priority_table_red t2 on t1.priority=t2.priority")
  #dim(df1)
  
  # large_mammals (Only need to create land cover with largeMam or smallMam but not both as they both have the same class values)
  df1 <- df1[!is.na(df1$priority),]
  
  print("priority part done")
  
  #largeMam <- df1 %>% dplyr::select("feature", "type", "view", "priority") # We should call this largeMam obj something else to avoid confusion
  
  largeMam <- df1[,c("feature", "type", "view", "priority")] # We should call this largeMam obj something else to avoid confusion
  #head(largeMam)
  
  largeMam$type <- ifelse(is.na(largeMam$type), 'NULL', largeMam$type)
  
  featUrb <- unique(df1$view)
  #head(featUrb)
  
  # To save list of features of each city
  #dir.create(paste0(outF, "/", city[k],"/","misc"))
  
  #saveRDS(df1, paste0(outF, "/", city[k],"/","misc", "/","df1"))
  
  #detach("package:dplyr", unload=TRUE)
  
  print("features part done")
  
  # end.time <- Sys.time()
  # time.taken <- end.time - start.time
  # time.taken
   
  # ------------------------------------------------------------
  # Query individual layers in PG OSM database to create rasters
  
  for (i in 1:length(featUrb)) {
    
    vals <- sqldf::sqldf(paste0("SELECT distinct priority FROM largeMam WHERE view='", featUrb[i],"' ORDER BY priority;"))
    
    for (j in 1:nrow(vals)) {
      
      sqlPrimer <- sqldf::sqldf(paste0("SELECT distinct feature, type, priority, view FROM largeMam WHERE view='", featUrb[i],"' AND priority=", vals$priority[j], " ;"))
      
      
      queryEnv <- paste0("SELECT * FROM ",city[k],"_env", ";")
      
      # the [1] could be removed if there are no dups
 #      queryUrFts <- paste0("SELECT ", sqlPrimer$priority[1]," as class, geom 
 # FROM
 #  (",
 #                          
 #                          paste0("SELECT * FROM ", dfSf ,"WHERE view=","'" ,sqlPrimer$view[1], "'", " ", ifelse(grepl('NULL', paste(sqlPrimer$type, collapse = "', '")), paste0(" AND type IS NULL OR type ", paste0("IN (","'",paste(sqlPrimer$type, collapse = "', '"), "'", ")" )), paste0("AND TYPE IN (","'",paste(sqlPrimer$type, collapse = "', '"), "'", ")" ) )) ,
 #                          
 #                          
 #                          ") t1 ")
      
      dfSf$type <- ifelse(is.na(dfSf$type), 'NULL', dfSf$type)
      
      vectorUrFts <- dfSf[which(dfSf$view==sqlPrimer$view[1] & dfSf$type %in% sqlPrimer$type),]
      vectorUrFts$class <- sqlPrimer$priority[1]
      
      
      #vectorEnv <- terra::vect(sf::st_read(con_pg, query=queryEnv))
      
      raster1 <- terra::rast(vectorEnv, resolution=30, crs="EPSG:3857")
	  
	  print(paste("done feature", featUrb[i]))
      
      #queryUrFts <- paste0("SELECT * FROM ", city[i],"_ur_fts", ";" )
      
      #vectorUrFts <- try(terra::vect(sf::st_read(con_pg, query=queryUrFts)) ) # when vector has no rows then Warning: 1: [SpatVector from sf] empty SpatVector
      
      #if(class(vectorUrFts) == "try-error") { vectorUrFts <- c() }
      
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

# sam1 <- sample(10, terra::as.points(rasterRes1, values=TRUE, na.rm=TRUE, na.all=FALSE), replace=FALSE)
# 
# sam1 <- terra::spatSample(r3, 10, method="stratified", replace=FALSE, na.rm=FALSE, 
#            as.raster=FALSE, as.df=TRUE, as.points=TRUE, values=TRUE, cells=TRUE, 
#            xy=TRUE, ext=NULL, warn=TRUE, weights=NULL, exp=5)
# 
# names(sam1) <- c("cell", "x", "y", "value")
# 
# terra::plot(sam1,"value", type="classes")
# 
# #terra::writeVector(sam1, paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample1", ".shp"), filetype="ESRI Shapefile", layer=NULL, insert=FALSE,
# #           overwrite=TRUE, options="ENCODING=UTF-8")
# 
# terra::writeVector(sam1, paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample1", ".geojson"), filetype="GeoJson", layer=NULL, insert=FALSE,
#                    overwrite=TRUE, options="ENCODING=UTF-8")
# 
# sam1Df <- as.data.frame(sam1[,c(1,4)])
# dim(sam1Df)
# 
# featureLabs <- (unique(largeMam[largeMam$view!='water', c(3,4)])) # You need to get rid of water or waterways otherwise you get duplicates
# 
# sam1Df2 <- sqldf("SELECT t1.*, t2.view FROM sam1Df t1 JOIN featureLabs t2 ON t1.value=t2.priority")
# dim(sam1Df2)
# head(sam1Df2)
# sam1Df2$rowid <- 1:nrow(sam1Df2)
# 
# #write.csv(sam1Df2[order(sam1Df2$cell), c(4,1:3)], paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample1_df", ".csv") , row.names = FALSE)
# write.csv(sam1Df2[,c(4,1:3)], paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample1_df", ".csv") , row.names = FALSE)


