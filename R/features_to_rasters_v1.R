#============================================
# Multi-city structural Connectivity Project
#============================================

# 2023-01-02
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

#  Main aim: convert urban features to rasters

start.time <- Sys.time()

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
setwd("~/mcsc_proj/")


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



#==================================
# Create priority and resistance df
#==================================

# Restore object (see urban_features_master_list_v1.R)
df1 <- readRDS("df_unique_res.rds")

# clean df so that feature names match SQL VIEWS
df1$view <- ifelse(df1$view=='lf_roads', 'lf_roads_bf', df1$view)
df1$view <- ifelse(df1$view=='lf_rails', 'lf_rails_bf', df1$view)
 
# select relevant columns
df1 <- df1[,c(1,2,4,5, 7, 8)] 
# remove duplicates 
df1 <- df1[!duplicated(df1), ] 
 
resVals <- df1

str(resVals) 
head(resVals)

# large_mammals
largeMam <- resVals[!is.na(resVals$res_large_mammals),c(1:5)]

# small_mammals
smallMam <- resVals[!is.na(resVals$res_small_mammals),c(1:4, 6)]

names(largeMam) <- c("feature","type","priority", "view", "resistance")

names(smallMam) <- c("feature","type","priority", "view", "resistance")

#largeMam[order(largeMam$priority, -largeMam$resistance),] 

dim(largeMam)
str(largeMam) 
head(largeMam)

#nrow(sqldf("SELECT distinct feature,type, priority, resistance, view from largeMam;")) # check for dups


#===============================================
# Create rasters for each feature
#===============================================

city <- c('Peterborough')

#city <- c('Peterborough', 'Brantford')


featUrb <- unique(largeMam$view)

for (i in 1:length(featUrb)) {
  
  vals <- sqldf(paste0("SELECT distinct priority, resistance FROM largeMam WHERE view='", featUrb[i],"' ORDER BY priority, resistance;"))
  
  for (j in 1:nrow(vals)) { 
    
    sqlPrimer <- sqldf(paste0("SELECT distinct feature, type, priority, resistance, view FROM largeMam WHERE view='",featUrb[i],"' AND priority=",vals$priority[j], " AND resistance=", vals$resistance[j], " ORDER BY resistance;"))

    # _bf (buffer) is a flag to remind us that we are converting the linear feat. ti polygons    
    if(featUrb[i] %in% (c("lf_roads", "lf_rails", "barrier"))) {
      sqlPrimer$view <- gsub(featUrb[i], paste0(featUrb[i],"_bf"), sqlPrimer$view) 
      }
      
    
    for (k in 1:length(city)) {
      
      
      queryEnv <- paste0("SELECT * FROM ",city[k],"_env", ";")
      
      # the [1] could be removed if there are no dups  
      queryUrFts <-paste0("SELECT ", sqlPrimer$resistance[1]," as resistance, geom 
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
  
  vectorUrFts <- vect(st_read(con_pg, query=queryUrFts)) # when vector has no rows then Warning: 1: [SpatVector from sf] empty SpatVector
  
  if( length(vectorUrFts)==0) 
  { print("empty vector")} else
    
  { 
    rasterRes1 <- rasterize(vectorUrFts, raster1, field="resistance", background=NA, touches=FALSE,
                            update=FALSE, sum=FALSE, cover=FALSE, overwrite=FALSE)
    
    dir.create("rasters")
    dir.create(paste0("rasters/",city[k]))
    
    writeRaster(rasterRes1, paste0("rasters/",city[k],"/",sqlPrimer$view[1],"__",sqlPrimer$priority[1],"__",sqlPrimer$resistance[1],".tif"), overwrite=TRUE)
  }
  
  
    }
    
  }
  
}



#=========================
# Stack & collapse rasters
#=========================

# Read raster based on priority flag first, then stack, and collapse

rasterFiles <- list.files(paste0("rasters/",city[k]), pattern='.tif$', full.names = TRUE)

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

r2 <- app(r1, fun='first', na.rm=TRUE)

r3 <- subst(r2, NA, 50)

dir.create(paste0("rasters/",city[k],"/output"))
writeRaster(r3, paste0("rasters/",city[k],"/output/",'urban_features.tif'), overwrite=TRUE)

# disconnect from db
dbDisconnect(con_pg)


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken
