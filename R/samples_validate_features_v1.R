#===========================================================
# Multi-city structural Connectivity Project -- Validate OSM
#===========================================================

# 2023-09-03
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

#  Main aim: Get samples to validate OSM features. This code should be run locally (not server necessarily)
# THis code was used to produce sample points for Joaquin to check

#start.time <- Sys.time()
#start.time

#===================
# Libraries
#===================

#sessionInfo()
#library(DBI)
#library(RPostgreSQL)
#library(sf)
library(terra)
#install.packages("sqldf")
library(sqldf)
#library(dplyr)
library(foreach)



#==================================
# Set folder & files paths - STEP 1
#==================================
# github project folder on server
#setwd("~/projects/def-mfortin/georod/scripts/mcsc/")
# project folder on desktop
#setwd("~/github/mcsc/")
setwd("C:/Users/Peter R/github/mcsc")
##Tiziana's working directory for this project
#setwd("C:/Users/tizge/Documents/StructuralconnectivityDB/")

# project output folder
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/mcsc_proj/"
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/test6/peter_newcode/lcrasters/Toronto/"
inF <- "C:/Users/Peter R/Documents/PhD/tiziana/mcsc_proj/mammals/"
outF <- "C:/Users/Peter R/Documents/PhD/tiziana/mcsc_proj/mammals/sample_pts/"
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/osm_validation/mammals/"
#project output on server
#outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/mammals/"

##Tiziana's output folder for this project'
#outF <- "C:/Users/tizge/Documents/StructuralconnectivityDB/largemam/"
#outF <- "C:/Users/Peter R/Documents/mcsc_proj/largemam"


#===============================
# files needed to run this
#================================

# table with the priority, resistance and source strength
priority_table <- read.csv('./misc/priority_table_v2.csv')
cec_table <- read.csv('./misc/cec_north_america_lcover_values.csv')
city <- read.csv("./misc/mcsc_city_list1.csv")



#========================
# Sample for validation
#========================

city <- city[!is.na(city$osm_id),]
city$pg_city <- gsub(" ", "_", city$osm_city)
#2023-07-23 (Toronto or Peterborough done by Joaquin separately)
#city <- city[1:4,6] #[1] "Wilmington"  "Edmonton"    "Phoenix"     "Little_Rock"
#city <- city[6:10,6] #[1] "Vancouver"    "Berkeley"     "Pasadena"     "Pomona"       "Fort_Collins"
city <- city[7:10,6] #[1] "Vancouver"    "Berkeley"     "Pasadena"     "Pomona"       "Fort_Collins"
#city <- city[c(11, 13:18, 20),6] #Atlanta...Syracuse # I had to skip chicago, new york
#city <- city[c(20),6] #Syracuse
city <- city[c(21:22,25:30),6] #Skip Toronto, Peterborough as they were done previously

for (k in 1:length(city)) {
  
  sam0 <- terra::rast(paste0(inF,"lcrasters/",city[k],"/output/",'all_lcover.tif'))
  
  set.seed(42) # Added on 2023-07-23 (not Toronto or Peterborough runs done by Joaquin)
  sam1 <- terra::spatSample(sam0, 10, method="stratified", replace=FALSE, na.rm=TRUE, 
                            as.raster=FALSE, as.df=TRUE, as.points=TRUE, values=TRUE, cells=TRUE, 
                            xy=FALSE, ext=NULL, warn=TRUE, weights=NULL, exp=5)
  
  sam1$rowid <- 1:nrow(sam1)
  names(sam1) <- c("cell", "value", "rowid")
  
# get x, y coordinates
  coords1 <- as.data.frame(crds(project(sam1, "EPSG:4326")))
  coords1$rowid <- 1:nrow(coords1)
  
  #rCEC <- terra::rast(paste0(inF,"lcrasters/",city[k],"/output/",'cec2_lcover.tif'))
  #lcDf <- extract(rCEC, sam1, bind=F)
  
  #terra::plot(sam1,"value", type="classes")
  
  #terra::writeVector(sam1, paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample1", ".shp"), filetype="ESRI Shapefile", layer=NULL, insert=FALSE,
  #           overwrite=TRUE, options="ENCODING=UTF-8")
  
  
  #dim(sam1Df)
  
  featureLabs <- unique(priority_table[,c(2,3)])
  
  featureLabs <- (unique(featureLabs[featureLabs$feature!='waterways', ])) # You need to get rid of water or waterways otherwise you get duplicates
  featureLabs[nrow(featureLabs) + 1,] <- c(0, "null_water")
  
  dir.create(paste0(outF,city[k]))
  
  sam1 <- merge(sam1, featureLabs, all.x=TRUE, by.x=c('value'), by.y=c('priority'))
  
  terra::writeVector(sam1, paste0(outF,city[k],"/", city[k], "_sample1", ".geojson"), filetype="GeoJson", layer=NULL, insert=FALSE,
                     overwrite=TRUE, options="ENCODING=UTF-8")
  
  sam1Df <- as.data.frame(sam1[,c(1,2,3,4)])
  
  sam1Df2 <- sqldf("SELECT t1.rowid, t1.cell, t3.y, t3.x, t1.value, t1.feature FROM sam1Df t1 JOIN coords1 t3 ON t1.rowid=t3.rowid")
  print(dim(sam1Df2))
  #head(sam1Df2)
  #sam1Df2$rowid <- 1:nrow(sam1Df2)
  
  
  #write.csv(sam1Df2[order(sam1Df2$cell), c(4,1:3)], paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample1_df", ".csv") , row.names = FALSE)
  write.csv(sam1Df2, paste0(outF, city[k],"/", city[k], "_sample1_df", ".csv") , row.names = FALSE)
  

  
}

# step 2: send CSV and geojson for Joaquin but check geojson in  QGIS first. Note that the CSV has more filed than the geojson.
# step 3: load geojson files in QGIS and create images for Tiziana
# step 4: run CEC code below and insert CEC fields into file for Tiziana to check. Convert file into Excel, name it as City_Completed2.xlsx


#----------------------------------------------------------------------------
# Add CEC land cover values to facilitate OSM validation
#----------------------------------------------------------------------------

# 2023-07-31

dataf2 <- "C:/Users/Peter R/Documents/PhD/tiziana/osm_validation/joaquins_work/completed_cities/"

fpath10 <- "C:/Users/Peter R/Documents/PhD/tiziana/mcsc_proj/mammals/sample_pts/"

outF <- fpath10

r4 <- rast("C:/Users/Peter R/Documents/data/gis/cec/Land_cover_2015v2_30m_TIF/NA_NALCMS_landcover_2015v2_30m/data/NA_NALCMS_landcover_2015v2_30m.tif")


city <- c("Edmonton", "Little_Rock", "Phoenix", "Wilmington")


pts1 <- list.files(fpath10, pattern=".geojson", recursive=T, full.names = T)
#pts1 <- pts1[c(2, 4, 6, 9)]
pts1 <- pts1[c(3, 13, 15, 7)] # Berklry, Pasadena, Pomona, Fort Collins


extract1 <- foreach (i=1:length(pts1)) %do% {
  
  terra::extract(r4, project(vect(pts1[i]), r4), )
  
}

# Write to csv
for (i in 1:length(pts1))  {
  
  write.csv(extract1[[i]], paste0(outF, city[i],"/", city[i], "_sample1_df_cec", ".csv") , row.names = FALSE)
  
}





