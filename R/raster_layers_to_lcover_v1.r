#============================================
# Multi-city structural Connectivity Project
#============================================

# 2023-06-19
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

#  Main aim: Join all raster layers derived from OSM into a single land cover raster

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
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/test2/"
#project output on server
#outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/smallmam/"
#res <- 'res_SM'

## loop creates both resistance maps anyways
outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/mammals/"

##Tiziana's output folder for this project'
#outF <- "C:/Users/tizge/Documents/StructuralconnectivityDB/largemam/"
#outF <- "C:/Users/Peter R/Documents/mcsc_proj/largemam"


#===============================
# files needed to run this
#================================
## might have to ad a path to subfolder data/

# list of cities with OSM ID
#city <- read.csv("./misc/mcsc_city_list1.csv")
# table with all the views we create with PG admin
#view_table <- read.csv('./misc/reference_all_views.csv', header=TRUE)
view_table <- read.csv('./misc/reference_all_views.csv', header=TRUE)
# table with the priority, resistance and source strength
priority_table <- read.csv('./misc/priority_table_v2.csv')

resTab <- read.csv("./misc/priority_table_v2.csv")
#tables with the classes included in the Global landcover and their equivalence to our OSM-derived landcover classes
cec <- read.csv('./misc/cec_north_america.csv')
cop <- read.csv('./misc/copernicus_reclassification_table.csv') 

#=====================================
# Fill in gaps with Land cover raster 
#=====================================

# Perhaps it is best to run this code separately so that the lcover raster is only run once.

#local test raster
#r4 <- rast("C:/Users/Peter R/Documents/data/ont_Red.tif")
r4 <- rast("~/projects/def-mfortin/georod/data/cec/NA_NALCMS_2015_LC_30m_LAEA_mmu5pix_.tif")

cecRes <- read.csv("./misc/cec_north_america_resistance_values.csv")

resTab <- read.csv("./misc/resistance_table.csv")


#-------------------------------
# Modify CSVs
#-------------------------------

###reclassification table for CEC
pri <- priority_table %>% dplyr::select(feature, priority)
colnames(pri)<- c('mcsc', 'mcsc_value')
cec <- read.csv('cec_north_america.csv')
rec_cec <- left_join(cec, pri, by='mcsc')
rec_cec_final <- rec_cec %>% mutate(mcsc_value = ifelse(mcsc == 'developed_na', 28, mcsc_value))
#write.csv(rec_cec_final, 'reclass_cec_2_mcsc.csv')
#rec_cec_final <- read.csv('reclass_cec_2_mcsc.csv')

###reclassification table for copernicus
cop <- read.csv('copernicus_reclassification_table.csv') %>% dplyr::select (copernicus, value, mcsc)
rec_cop <- left_join(cop, pri, by='mcsc')
rec_cop %>% filter(is.na(mcsc_value)) 
#rec_cop$mcsc[6]<-'linear_feature_na_traffic' 
rec_cop$mcsc[7]<-'linear_feature_na_traffic' 
rec_cop$mcsc[23]<-'linear_feature_vh_traffic'
rec_cop$mcsc[9]<-'linear_feature_rail'   
rec_cop <- rec_cop %>% dplyr::select(1,2,3)
rec_cop <- left_join(rec_cop, pri, by='mcsc')
rec_cop_final <- rec_cop %>% mutate(mcsc_value= ifelse(mcsc == 'developed_na', 28, mcsc_value))
# write.csv(rec_cop_final, 'reclass_copernicus_2_mcsc.csv')
# rec_cop_final <- read.csv('reclass_copernicus_2_mcsc.csv')
cecRes <- rec_cec_final
#cecRes <- read.csv("./misc/cec_north_america_resistance_values.csv")


## we dont really need this I think
resTab <- read.csv("priority_table_v2.csv")
#resTab <- read.csv("./misc/resistance_table.csv")
##fixing the table for these, and adding here quickly strength values
resTab$class <- resTab$priority
resTab$res_large_mammals <- resTab$res_LM
resTab$res_small_mammals <- resTab$res_SM
resTab$source_strength <- resTab$source_strength


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

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

# disconnect from db
#dbDisconnect(con_pg)
