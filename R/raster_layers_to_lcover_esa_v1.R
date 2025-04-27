#============================================================================
# Multi-city structural Connectivity Project - Augment Global Landcover (ESA)
#============================================================================

# 2023-08-22
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

# Main aim: Augment Global land cover with OSM land cover rasters. 
# Notes:
# - Here I use the ESA land cover data which required a different workflow than CEC
# - Basically ESA is 10 m resolution and comes in hundreds of small rasters.
# - It is not efficient to merge all the rasters and then clip to a city extent
# - Instead, here we find which rasters overlap (intersect) with a city envelop and then
#   we merge only that subset of raster files

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
library(foreach)
library(sqldf)
library(dplyr)


#==================================
# Set folder & files paths - STEP 1
#==================================
# github project folder on server
setwd("~/projects/def-mfortin/georod/scripts/github/mcsc/")
# project folder on desktop
#setwd("~/github/mcsc/")
#setwd("C:/Users/Peter R/github/mcsc")
##Tiziana's working directory for this project
#setwd("C:/Users/tizge/Documents/StructuralconnectivityDB/")

# project output folder
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/mcsc_proj/mammals/"
#project output on server
#outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/smallmam/"

outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/mammals/"

##Tiziana's output folder for this project'
#outF <- "C:/Users/tizge/Documents/StructuralconnectivityDB/largemam/"
#outF <- "C:/Users/Peter R/Documents/mcsc_proj/largemam"


#===============================
# files needed to run this
#================================
## might have to ad a path to subfolder data/

# list of cities with OSM ID
city <- read.csv("./misc/mcsc_city_list1.csv")
# table with the priority, resistance and source strength
priority_table <- read.csv('./misc/priority_table_v2.csv')

#resTab <- read.csv("./misc/priority_table_v2.csv")
#tables with the classes included in the Global landcover and their equivalence to our OSM-derived landcover classes
#cec <- read.csv('./misc/cec_north_america.csv')
#cop <- read.csv('./misc/copernicus_reclassification_table.csv') 
cec <- read.csv('./misc/esa.csv') # I will keep the name cec so to avoid changing the code below


#=====================================
# Fill in gaps with Land cover raster 
#=====================================

# Perhaps it is best to run this code separately so that the lcover raster is only run once.

#local test raster, Ontario only
#r4 <- terra::rast("C:/Users/Peter R/Documents/data/gis/cec/NA_NALCMS_2015_LC_30m_LAEA_mmu5pix_.tif")
# Compete raster for North America
#r4 <- rast("~/projects/def-mfortin/georod/data/cec/NA_NALCMS_2015_LC_30m_LAEA_mmu5pix_.tif")
# This is the new version of CEC
#r4 <- rast("~/projects/def-mfortin/georod/data/cec/NA_NALCMS_landcover_2015v2_30m/data/NA_NALCMS_landcover_2015v2_30m.tif")
#r4 <- rast("C:/Users/Peter R/Documents/data/gis/cec/Land_cover_2015v2_30m_TIF/NA_NALCMS_landcover_2015v2_30m/data/NA_NALCMS_landcover_2015v2_30m.tif")
#r4 <- rast("~/projects/def-mfortin/georod/data/cec/NA_NALCMS_landcover_2015v2_30m/data/esa.tif")

#cecRes <- read.csv("./misc/cec_north_america_resistance_values.csv")

#priority_table <- read.csv("./misc/resistance_table.csv")

city <- city[!is.na(city$osm_id),]
city$pg_city <- gsub(" ", "_", city$osm_city)

#city <- city[(city$pg_city %in% c('Houston')), 6]
#city <- city[(city$pg_city %in% c('Phoenix')), 6]
#city <- city[(city$pg_city %in% c('Peterborough')),6]
#city <- city[(city$pg_city %in% c('Toronto')), 6]
#city <- city[1:4 ,6] #Skip Freiburg
#city <- city[6:10 ,6]
#city <- city[c(1:4, 6:15, 17:30,32:35) ,6] # #Skip Freiburg & Aromas. Also Mexico city until I download the tile for Mexico (16).
#city <- city[c(36),6] # Jackson
#city <- city[c(37),6] # Key Largo
#city <- city[c(38),6] # Golden Horseshoe
#city <- city[c(12),6] # Chicago
#city <- city[c(1:4, 6:15, 17:30,32:36,38) ,6] # #Skip Freiburg & Aromas. Also Mexico city until I download the tile for Mexico (16). Key Largo did not work, skipping it.
#city <- city[c(39:40),6] # Seattle, San Francisco
#city <- city[c(41),6] # Indianapolis
#city <- city[c(42,43),6] # Berkeley2, Indianapolis3


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


#-------------------------------
# Modify CSVs
#-------------------------------

###reclassification table for CEC
pri <- priority_table %>% dplyr::select(feature, priority)
colnames(pri)<- c('mcsc', 'mcsc_value')
#cec <- read.csv('cec_north_america.csv')
rec_cec <- dplyr::left_join(cec, pri, by='mcsc')
rec_cec_final <- rec_cec %>% mutate(mcsc_value = ifelse(mcsc == 'developed_na', 28, mcsc_value)) # This is not really needed as pri obj already has 28
#write.csv(rec_cec_final, 'reclass_cec_2_mcsc.csv')
#rec_cec_final <- read.csv('reclass_cec_2_mcsc.csv')
cecRes <- rec_cec_final

###reclassification table for copernicus
#cop <- read.csv('copernicus_reclassification_table.csv') %>% dplyr::select (copernicus, value, mcsc)
# rec_cop <- left_join(cop, pri, by='mcsc')
# #rec_cop %>% filter(is.na(mcsc_value.y)) #PR: ask Tiziana if x or y. Is seems not to matter
# #rec_cop$mcsc[6]<-'linear_feature_na_traffic' 
# rec_cop$mcsc[7]<-'linear_feature_na_traffic' 
# rec_cop$mcsc[23]<-'linear_feature_vh_traffic'
# rec_cop$mcsc[9]<-'linear_feature_rail'   
# rec_cop <- rec_cop %>% dplyr::select(1,2,3)
# rec_cop <- left_join(rec_cop, pri, by='mcsc')
# rec_cop_final <- rec_cop %>% mutate(mcsc_value= ifelse(mcsc == 'developed_na', 28, mcsc_value))
# # write.csv(rec_cop_final, 'reclass_copernicus_2_mcsc.csv')
# rec_cop_final <- read.csv('reclass_copernicus_2_mcsc.csv')
#cecRes <- rec_cec_final
#cecRes <- read.csv("./misc/cec_north_america_resistance_values.csv")



# Crop North America land cover map first

#ext1 <- ext(r3)
#ext1 <- as.polygons(ext(r3))
#crs(ext1) <- "EPSG:3857"


for (k in 1:length(city)) {
  
  queryEnv <- paste0("SELECT * FROM ",city[k],"_env", ";")
  vectorEnv <- terra::vect(sf::st_read(con_pg, query=queryEnv))
  
  print(paste0("processing city: ", city[k]))
  
# Load city raster  
r3 <- terra::rast(paste0(outF,"lcrasters/",city[k],"/output/",'osm_lcover.tif'))

# Get city extent
# Get extent of city envelope
ext1 <- terra::buffer(vectorEnv, width=500)
cityExt <- ext(terra::project(ext1, "EPSG:4326")) # The project of ESA is EPSG:4326

# Read all ESA rasters (> 100 rasters)
rFiles1 <- list.files(path="~/projects/def-mfortin/georod/data/esa", pattern="*.tif$", full.names = T, recursive = T) 
#length(rFiles1)

# Find which rasters overlap with city raster
rExtL1 <- foreach (i=1:length(rFiles1)) %do% {
  
  cbind.data.frame("rFile"=i, "intersects1"=terra::relate(terra::ext(terra::rast(rFiles1[i])), cityExt, relation="intersects")) 
  
}

rExtDf1 <- do.call("rbind", rExtL1)
rExtIndex <- rExtDf1[rExtDf1$intersects1==TRUE, 1]

# Subset ESA raster files lists for merging. This is to avoid merging hundreds of rasters
rFiles2 <- (rFiles1[rExtIndex])
print("done subsetting rasters files")


# Note: the merge and mosaic functions were given this error: Error: std::bad_alloc
# for this reason, I had to change the code to use vrt() instead
# if (length(rFiles2)>1) {
# # Read rasters into a spatial collection
# #rL1 <- list(terra::rast(rFiles2))
# # Create a raster spatial collection
# rL1spc <- terra::sprc(rFiles2)
# print("done creating raster spatial collection")
# } else { 
#     rL1spc <- terra::rast(rFiles2)
#     print("done reading raster, no spatial collection")
# }

# Merge/mosaic ESA rasters
# for this reason I used vrt (virtual raster) function
#r4 <- terra::merge(rL1spc)
#print("done merging rasters")

# create virtual raster instead of using merge/mosaic. vrt in a way does a merge.
r4  <- vrt(rFiles2)

# Get crs of ESA raster
newcrs <- terra::crs(r4, proj=TRUE)
# Project to ESA raster projection
ext1Pj <- terra::project(ext1, newcrs)

# Crop ESA land cover to city envelope extent
r5 <- terra::crop(r4, ext1Pj) # for some cities extPj has a lower ymin 
print("done cropping rasters")

terra::writeRaster(r5, paste0(outF,"lcrasters/",city[k],"/output/",'esa.tif'), overwrite=TRUE)
print("done writing original raster")

# Given that one is Geographic and the other planar, it is safer to project
#fact1 <- round(dim(r5)[1:2] / dim(r3)[1:2]) # high resolution raster / low resolution raster. Proj does not need to be the same but should be equivalent extents
fact1 <- round(dim(r5)[1:2] / dim(terra::project(r3, newcrs))[1:2])

r5 <- terra::aggregate(r5, fact1, fun="modal", na.rm=T)
print("done aggregating raster")

# transform cropped raster crs to EPSG 3857 , "EPSG:3857"
r6 <- terra::project(r5, r3, method="near", align=TRUE)
# crop to ensure rasters have the same extent

r6 <- terra::crop(r6, r3)
r6 <- terra::extend(r6, r3) # this is to ensure the rasters line up before masking. Houston was creating problems.
print("done extending raster")

#terra::writeRaster(r6, paste0(outF,"lcrasters/",city[k],"/output/",'cec_lcover.tif'), overwrite=TRUE)
terra::writeRaster(r6, paste0(outF,"lcrasters/",city[k],"/output/",'esa_lcover.tif'), overwrite=TRUE)
#plot(r6, type="classes")
print("done writing raster")

# Mask raster
r7 <- terra::mask(r6, r3, inverse=TRUE, maskvalue=NA) # this is for insurance
print("done masking raster 1")

rclM <- as.matrix(cecRes[,c(2,4)])
#rclM <- matrix(rclM, ncol=2, byrow=TRUE)
r8 <- terra::classify(r7, rclM) # Save this?
terra::writeRaster(r8, paste0(outF,"lcrasters/",city[k],"/output/",'esa2_lcover.tif'), overwrite=TRUE)
#plot(r8, type="classes")
print("done writing raster 2")

r9 <- terra::cover(r3, r8)
r9 <- terra::subst(r9, 0, 12)
#plot(r9, type="classes")
terra::writeRaster(r9, paste0(outF,"lcrasters/",city[k],"/output/",'all_lcover2.tif'), overwrite=TRUE)
print("done writing raster 3")


# Create large mammal raster
rclMlargeMam <- as.matrix(priority_table[,c("priority", "res_LM")])
r10 <- terra::classify(r9, rclMlargeMam)
terra::writeRaster(r10, paste0(outF,"lcrasters/",city[k],"/output/",'largemam_res2.tif'), overwrite=TRUE)
print("done writing raster 4")


# Create small mammal raster
rclMsmallMam <- as.matrix(priority_table[,c("priority", "res_SM")])
r11 <- terra::classify(r9, rclMsmallMam)
terra::writeRaster(r11, paste0(outF,"lcrasters/",city[k],"/output/",'smallmam_res2.tif'), overwrite=TRUE)
print("done writing raster 5")


# Create source strength
rclMsourceStr <- as.matrix(priority_table[,c("priority", "source_strength")])
r12 <- terra::classify(r9, rclMsourceStr)
terra::writeRaster(r12, paste0(outF,"lcrasters/",city[k],"/output/",'source_strength2.tif'), overwrite=TRUE)

print("done writing raster 6")

}


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

# disconnect from db
dbDisconnect(con_pg)

print("done creating rasters")




