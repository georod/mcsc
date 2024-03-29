#============================================
# Multi-city structural Connectivity Project
#============================================

# 2023-02-03
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

#  Main aim: convert OSM & CEC land cover tp new land cover raster
#  Note: the new land cover raster created here is to help validate the resistance rasters created in features_to_rasters_v2.R

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

library(dplyr)


#=================================
# Set folder & files paths
#=================================
# github project folder on server
setwd("~/projects/def-mfortin/georod/scripts/mcsc/")
# project folder on desktop
#setwd("~/github/mcsc/")

# project output folder
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/test2/"
#outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/smallmam/"
outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/largemam/"


#=================================
# Connect to PG db
#=================================
# add username and pwd to .Renviron
# con_pg <- DBI::dbConnect(
#   drv = RPostgres::Postgres(),
#   host = "localhost",
#   port = 5432,
#   dbname = "osm",
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



#===============================================
# Create rasters for each feature
#===============================================

#city <- c('Mexico')
#city <- c('Toronto', 'City_of_New_York', 'Atlanta', 'Berkeley', 'Boston', 'Fort_Worth', 'Edmonton', 'Fort_Collins', 'Houston','Little_Rock', 'Manchester', 'Maryland', 'Pasadena', 'Phoenix', 'Pomona', 'Salt_Lake_City', 'Saskatoon', 'St_Louis', 'Syracuse', 'Vancouver', 'Wilmington', 'Urbana', 'Mexico')
#city <- c('Vancouver', 'Wilmington', 'Urbana')
#city <- c('Little_Rock', 'Manchester', 'Maryland', 'Pasadena', 'Phoenix', 'Pomona', 'Salt_Lake_City', 'Saskatoon', 'St_Louis', 'Syracuse', 'Vancouver', 'Wilmington', 'Urbana')
#city <- c('Toronto', 'City_of_New_York', 'Atlanta', 'Berkeley', 'Boston', 'Fort_Worth', 'Edmonton', 'Fort_Collins', 'Houston')
#city <- c('Toronto', 'City_of_New_York', 'Fort_Collins') 
#city <- c('Toronto')
city <- c('Chicago', 'Boston')
#city <- c('City_of_New_York')
#city <- c('City_of_New_York', 'Chicago')
#city <- c('Fort_Collins')
#city <- c('City_of_New_York', 'Fort_Collins', 'Chicago')
#city <- c('Peterborough')
#city <- c('Peterborough', 'Brantford')
#city <- c('Peterborough')

#featUrb <- unique(largeMam$view) 
#featUrb <- unique(smallMam$view)
#featUrb <- featUrb[c(14:length(featUrb))]


# SQL code to create city specific urban features.

pg_views1 <-  c("buildings", "lf_roads_notraffic_bf", "lf_roads_very_low_traffic_bf", "lf_roads_low_traffic_bf", "lf_roads_medium_traffic_bf", "lf_roads_high_traffic_ls_bf", "lf_roads_high_traffic_hs_bf", "lf_roads_very_high_traffic_bf", "lf_roads_unclassified_bf", "lf_rails_bf", "open_green", "protected_area", "hetero_green", "dense_green", "resourceful_green", "water", "parking_surface", "residential", "railway_landuse", "commercial_industrial", "institutional", "barrier_bf" )
# length(pg_views1)

sqlList1 <- list()

for (i in 1:length(pg_views1)){

sqlList1[i] <- paste0("SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric,", "'", pg_views1[i],"'", " AS view FROM ", pg_views1[i], " t1 JOIN ",
   city[k],"_env", " t2 ON st_intersects(t1.geom,t2.geom)")
   }

   

#length(sqlList1)   
#sqlUni <- paste0(sqlList1[[1]], " UNION ALL ", sqlList1[[2]],
 
sqlUnion1 <- do.call(paste, c(sqlList1, sep=" UNION ALL ")) 
 

 df <- dbGetQuery(con_pg, paste0(
"SELECT DISTINCT feature, type, material, size, view, row_number() OVER (ORDER BY view, feature) AS rid FROM (", sqlUnion1, ") t1;") )



#-------------------------------------------------
# Urban features master list
#-------------------------------------------------

##create table with priority values
df_unique <- df %>% dplyr::count(feature, type, material, size, view, .drop=FALSE)

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
  #mutate(priority = ifelse(feature == "linear_feature_no_traffic" & (material != 'sidewalk' | is.na(material)), 24, priority))%>% ### sidewalks. #PR

  #mutate(priority = ifelse(feature == "linear_feature_no_traffic" & material == 'sidewalk', 20, priority))%>%
  ##railways
  mutate(priority = ifelse(feature == "linear_feature_rail", 25, priority))%>%
  mutate(priority = ifelse(feature == "linear_feature_rail" & (type %in% c('abandoned','disused','construction') | material == 'construction'), 26, priority))%>%
  #mutate(priority = ifelse(feature == "linear_feature_rail" & type %in% c('abandoned','disused','construction') , 26, priority))%>%
  #mutate(priority = ifelse(feature == "linear_feature_rail" & material == 'construction', 26, priority))%>%
  ##barriers (too thin to appear on 30m resolution layer, useful for other purposes) 
  mutate(priority = ifelse(feature == "barrier", 27, priority)) ## the

# Add new column "class" 
#df_unique_res$class <- df_unique_res$priority


#==================================
# Create priority df
#==================================


# select relevant columns
#df1 <- df1[,c(1,2,4,8,9)] 
df1 <- df1[,c('feature', 'type', 'view', 'priority')]

# remove duplicates 
df1 <- df1[!duplicated(df1), ] 

#resVals <- df1

#str(resVals) 
#head(resVals)

# large_mammals (Only need to create land cover with largeMam or smallMam but not both as they both have the same class values)
largeMam <- df1[!is.na(df1$priority),c(1:4)]

# small_mammals
#smallMam <- resVals[!is.na(resVals$res_small_mammals),c(1:4, 6)]

names(largeMam) <- c("feature","type", "view", "priority")

#names(smallMam) <- c("feature","type", "view", "resistance", "priority", "class")

#largeMam[order(largeMam$priority, -largeMam$resistance),] 

#dim(largeMam)
#str(largeMam) 
#head(largeMam)

#nrow(sqldf("SELECT distinct feature,type, priority, resistance, view from largeMam;")) # check for dups

featUrb <- unique(largeMam$view) 
 


                 

#--------------------------------------------------
#
#--------------------------------------------------

for (k in 1:length(city)) {


#-----------------------------------
# Create city-specific urban features
#-----------------------------------

sqlList1 <- list()

for (p in 1:length(pg_views1)){

sqlList1[p] <- paste0("SELECT t1.feature, CASE WHEN t1.type is null then 'NULL' else t1.type END AS type, t1.material, t1.size::numeric,", "'", pg_views1[p],"'", " AS view FROM ", pg_views1[p], " t1 JOIN ",
   city[k],"_env", " t2 ON st_intersects(t1.geom,t2.geom)")
   
   }

sqlUnion1 <- do.call(paste, c(sqlList1, sep=" UNION ALL ")) 
 

df <- dbGetQuery(con_pg, paste0(
"SELECT DISTINCT feature, type, material, size, view, row_number() OVER (ORDER BY view, feature) AS rid FROM (", sqlUnion1, ") t1;") )


#----------------------------------
# Create city specific priority df
#----------------------------------

##create table with priority values
df_unique <- df %>% dplyr::count(feature, type, material, size, view, .drop=FALSE)

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

df1 <- df1[,c('feature', 'type', 'view', 'priority')]

# remove duplicates 
df1 <- df1[!duplicated(df1), ] 

# large_mammals (Only need to create land cover with largeMam or smallMam but not both as they both have the same class values)
largeMam <- df1[!is.na(df1$priority),c(1:4)]

names(largeMam) <- c("feature","type", "view", "priority")

featUrb <- unique(largeMam$view) 


# ------------------------------------------------------------
# Query individual layers in PG OSM database to create rasters

  for (i in 1:length(featUrb)) {

    vals <- sqldf(paste0("SELECT distinct priority FROM largeMam WHERE view='", featUrb[i],"' ORDER BY priority;"))

    for (j in 1:nrow(vals)) {

      sqlPrimer <- sqldf(paste0("SELECT distinct feature, type, priority, view FROM largeMam WHERE view='", featUrb[i],"' AND priority=", vals$priority[j], " ;"))


      queryEnv <- paste0("SELECT * FROM ",city[k],"_env", ";")

      # the [1] could be removed if there are no dups
      queryUrFts <-paste0("SELECT ", sqlPrimer$priority[1]," as class, geom
 FROM
 (
  SELECT (ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM (",

  paste0("SELECT * FROM ", sqlPrimer$view[1], " ",ifelse(grepl('NULL', paste(sqlPrimer$type, collapse = "', '")), paste0(" WHERE type IS NULL OR type ", paste0("IN (","'",paste(sqlPrimer$type, collapse = "', '"), "'", ")" )), paste0("WHERE TYPE IN (","'",paste(sqlPrimer$type, collapse = "', '"), "'", ")" ) )) ,


  ") t1
  JOIN
   ", city[k],"_env", " t2
  ON st_intersects(t1.geom,t2.geom)) t3;")

  vectorEnv <- vect(st_read(con_pg, query=queryEnv))

  raster1 <- rast(vectorEnv, resolution=30, crs=crs(vectorEnv))

  #queryUrFts <- paste0("SELECT * FROM ", city[i],"_ur_fts", ";" )

  vectorUrFts <- try(vect(st_read(con_pg, query=queryUrFts)) ) # when vector has no rows then Warning: 1: [SpatVector from sf] empty SpatVector

  if(class(vectorUrFts) == "try-error") { vectorUrFts <- c() }

  if( length(vectorUrFts)==0)
  { print("empty vector")} else

  {
    rasterRes1 <- rasterize(vectorUrFts, raster1, field="class", background=NA, touches=FALSE,
                            update=FALSE, sum=FALSE, cover=FALSE, overwrite=FALSE)

    dir.create(paste0(outF,"lcrasters"))
    dir.create(paste0(outF,"lcrasters/",city[k]))

    writeRaster(rasterRes1, paste0(outF,"lcrasters/",city[k],"/",sqlPrimer$view[1],"__",sqlPrimer$priority[1],"__",sqlPrimer$priority[1],".tif"), overwrite=TRUE)

  }

    }

  }


 }


# disconnect from db
#dbDisconnect(con_pg)


#end.time <- Sys.time()
#time.taken <- end.time - start.time
#time.taken


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

r1 <- rast(priOrd$rasterFiles)

r3 <- app(r1, fun='first', na.rm=TRUE)

#r3 <- subst(r2, NA, 50)
#r3 <- r2

dir.create(paste0(outF,"lcrasters/",city[k],"/output"))
writeRaster(r3, paste0(outF,"lcrasters/",city[k],"/output/",'osm_lcover.tif'), overwrite=TRUE)

}


#=================================
# Fill in with Land cover raster
#=================================

#local test raster
#r4 <- rast("C:/Users/Peter R/Documents/data/ont_Red.tif")
r4 <- rast("~/projects/def-mfortin/georod/data/cec/NA_NALCMS_2015_LC_30m_LAEA_mmu5pix_.tif")

cecRes <- read.csv("./misc/cec_north_america_resistance_values.csv")

resTab <- read.csv("./misc/resistance_table.csv")

# Crop North America land cover map first

#ext1 <- ext(r3)
#ext1 <- as.polygons(ext(r3))
#crs(ext1) <- "EPSG:3857"

for (k in 1:length(city)) {
  
  queryEnv <- paste0("SELECT * FROM ",city[k],"_env", ";")
  vectorEnv <- vect(st_read(con_pg, query=queryEnv))
  
# Get extent of city envelope
ext1 <- buffer(vectorEnv, width=500)
# Get crs of N. America raster
newcrs <- crs(r4, proj=TRUE)
# Project to North America raster projection
ext1Pj <- terra::project(ext1, newcrs)
# Crop NA land cover to city envelope extent
r5 <- crop(r4, ext1Pj)

r3 <- rast(paste0(outF,"lcrasters/",city[k],"/output/",'osm_lcover.tif'))

# transform cropped raster crs to EPSG 3857 , "EPSG:3857"
r6 <- project(r5, r3, method="near", align=TRUE)
# crop to ensure rasters have the same extent
r6 <- crop(r6, r3)
#plot(r6, type="classes")
# Mask raster
r7 <- mask(r6, r3, inverse=TRUE, maskvalue=NA)

rclM <- as.matrix(cecRes[,c(3,7)])
#rclM <- matrix(rclM, ncol=2, byrow=TRUE)
r8 <- classify(r7, rclM)
#plot(r8, type="classes")


r9 <- cover(r3, r8)
r9 <- subst(r9, 0, 100)
#plot(r9, type="classes")
writeRaster(r9, paste0(outF,"lcrasters/",city[k],"/output/",'all_lcover.tif'), overwrite=TRUE)



# Create large mammal raster
rclMlargeMam <- as.matrix(resTab[,c("class", "res_large_mammals")])
r10 <- classify(r9, rclMlargeMam)
writeRaster(r10, paste0(outF,"lcrasters/",city[k],"/output/",'largemam_res.tif'), overwrite=TRUE)


# Create small mammal raster
rclMsmallMam <- as.matrix(resTab[,c("class", "res_small_mammals")])
r11 <- classify(r9, rclMsmallMam)
writeRaster(r11, paste0(outF,"lcrasters/",city[k],"/output/",'smallmam_res.tif'), overwrite=TRUE)


# Create source strength
rclMsourceStr <- as.matrix(resTab[,c("class", "source_strength")])
r12 <- classify(r9, rclMsourceStr)
writeRaster(r12, paste0(outF,"lcrasters/",city[k],"/output/",'source_strength.tif'), overwrite=TRUE)


}

# disconnect from db
dbDisconnect(con_pg)


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken
