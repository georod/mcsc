#===========================================================
# Multi-city structural Connectivity Project -- Validate OSM
#===========================================================

# 2023-07-11
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

#  Main aim: Get samples to validate OSM features. This code should be run locally (not server necessarily)

start.time <- Sys.time()
start.time

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
outF <- "C:/Users/Peter R/Documents/PhD/tiziana/mcsc_proj/"
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


#========================
# Sample for validation
#========================

for (k in 1:length(city)) {
  
  sam0 <- terra::rast(paste0(outF,"lcrasters/",city[k],"/output/",'all_lcover.tif'))
  
  sam1 <- terra::spatSample(sam0, 10, method="stratified", replace=FALSE, na.rm=FALSE, 
                            as.raster=FALSE, as.df=TRUE, as.points=TRUE, values=TRUE, cells=TRUE, 
                            xy=FALSE, ext=NULL, warn=TRUE, weights=NULL, exp=5)
  
  names(sam1) <- c("cell", "value")
  
  #terra::plot(sam1,"value", type="classes")
  
  #terra::writeVector(sam1, paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample1", ".shp"), filetype="ESRI Shapefile", layer=NULL, insert=FALSE,
  #           overwrite=TRUE, options="ENCODING=UTF-8")
  
  terra::writeVector(sam1, paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample2", ".geojson"), filetype="GeoJson", layer=NULL, insert=FALSE,
                     overwrite=TRUE, options="ENCODING=UTF-8")
  
  sam1Df <- as.data.frame(sam1[,c(1,2)])
  #dim(sam1Df)
  
  featureLabs <- unique(priority_table[,c(2,3)])
  
  featureLabs <- (unique(featureLabs[featureLabs$feature!='waterways', ])) # You need to get rid of water or waterways otherwise you get duplicates
  
  sam1Df2 <- sqldf("SELECT t1.*, t2.feature FROM sam1Df t1 JOIN featureLabs t2 ON t1.value=t2.priority")
  #dim(sam1Df2)
  #head(sam1Df2)
  sam1Df2$rowid <- 1:nrow(sam1Df2)
  
  #write.csv(sam1Df2[order(sam1Df2$cell), c(4,1:3)], paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample1_df", ".csv") , row.names = FALSE)
  write.csv(sam1Df2[,c(4,1:3)], paste0(outF,"lcrasters/",city[k],"/output/", city[k], "_sample2_df", ".csv") , row.names = FALSE)
  
}