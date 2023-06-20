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


#==================================
# Create priority and resistance df
#==================================

# Restore object (see urban_features_master_list_v1.R)
df1 <- readRDS("./misc/df_unique_res.rds")

# clean df so that feature names match SQL VIEWS
#df1$view <- ifelse(df1$view=='lf_roads', 'lf_roads_bf', df1$view)
#df1$view <- ifelse(df1$view=='lf_rails', 'lf_rails_bf', df1$view)
#df1$view <- ifelse(df1$view=='barrier', 'barrier_bf', df1$view)

# select relevant columns
#df1 <- df1[,c(1,2,4,8,9)] 
df1 <- df1[,c('feature', 'type', 'view', 'priority', 'class')]

# remove duplicates 
df1 <- df1[!duplicated(df1), ] 

resVals <- df1

#str(resVals) 
#head(resVals)

# large_mammals (Only need to create land cover with largeMam or smallMam but not both as they both have the same class values)
largeMam <- resVals[!is.na(resVals$priority),c(1:5)]

# small_mammals
#smallMam <- resVals[!is.na(resVals$res_small_mammals),c(1:4, 6)]

names(largeMam) <- c("feature","type", "view", "priority", "class")

#names(smallMam) <- c("feature","type", "view", "resistance", "priority", "class")

#largeMam[order(largeMam$priority, -largeMam$resistance),] 

#dim(largeMam)
#str(largeMam) 
#head(largeMam)

#nrow(sqldf("SELECT distinct feature,type, priority, resistance, view from largeMam;")) # check for dups



#===============================================
# Create rasters for each feature
#===============================================

city <- c('Mexico')
#city <- c('Toronto', 'City_of_New_York', 'Atlanta', 'Berkeley', 'Boston', 'Fort_Worth', 'Edmonton', 'Fort_Collins', 'Houston','Little_Rock', 'Manchester', 'Maryland', 'Pasadena', 'Phoenix', 'Pomona', 'Salt_Lake_City', 'Saskatoon', 'St_Louis', 'Syracuse', 'Vancouver', 'Wilmington', 'Urbana')
#city <- c('Vancouver', 'Wilmington', 'Urbana')
#city <- c('Little_Rock', 'Manchester', 'Maryland', 'Pasadena', 'Phoenix', 'Pomona', 'Salt_Lake_City', 'Saskatoon', 'St_Louis', 'Syracuse', 'Vancouver', 'Wilmington', 'Urbana')
#city <- c('Toronto', 'City_of_New_York', 'Atlanta', 'Berkeley', 'Boston', 'Fort_Worth', 'Edmonton', 'Fort_Collins', 'Houston')
#city <- c('Toronto', 'City_of_New_York', 'Fort_Collins') 
#city <- c('Toronto')
#city <- c('Chicago')
#city <- c('City_of_New_York')
#city <- c('City_of_New_York', 'Chicago')
#city <- c('Fort_Collins')
#city <- c('City_of_New_York', 'Fort_Collins', 'Chicago')
#city <- c('Peterborough')
#city <- c('Peterborough', 'Brantford')
#city <- c('Peterborough')

featUrb <- unique(largeMam$view) 
#featUrb <- unique(smallMam$view)
#featUrb <- featUrb[c(14:length(featUrb))]


for (k in 1:length(city)) {

  for (i in 1:length(featUrb)) {

    vals <- sqldf(paste0("SELECT distinct priority, class FROM largeMam WHERE view='", featUrb[i],"' ORDER BY priority, class;"))

    for (j in 1:nrow(vals)) {

      sqlPrimer <- sqldf(paste0("SELECT distinct feature, type, priority, class, view FROM largeMam WHERE view='", featUrb[i],"' AND priority=",vals$priority[j], " AND class=", vals$class[j], " ORDER BY class;"))


      queryEnv <- paste0("SELECT * FROM ",city[k],"_env", ";")

      # the [1] could be removed if there are no dups
      queryUrFts <-paste0("SELECT ", sqlPrimer$class[1]," as class, geom
 FROM
 (
  SELECT (ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM (",

  #paste0("SELECT * FROM ", sqlPrimer$view[1], " WHERE type ", ifelse(paste0(paste(sqlPrimer$type, collapse = "', '"))=='none', 'IS NULL', paste0("IN (","'",paste(sqlPrimer$type, collapse = "', '"), "'", ")" ) )) ,
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

    writeRaster(rasterRes1, paste0(outF,"lcrasters/",city[k],"/",sqlPrimer$view[1],"__",sqlPrimer$priority[1],"__",sqlPrimer$class[1],".tif"), overwrite=TRUE)

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
