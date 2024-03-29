#============================================
# Multi-city structural Connectivity Project
#============================================

# 2023-06-19
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

#  Main aim: convert OSM & CEC land cover tp new land cover raster
#  Note: 2023-06-20 - this R script was called C:\Users\Peter R\github\mcsc\R\features_to_lcover_v4.R

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


#=================================
# Connect to PG db - STEP 2
#=================================
# add username and pwd to .Renviron
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
# Call views for city envelopes - STEP 3
#=========================================================

#select which cities to run
#city <- c('Mexico')
#city <- c('Toronto', 'City_of_New_York', 'Atlanta', 'Berkeley', 'Boston', 'Fort_Worth', 'Edmonton', 'Fort_Collins', 'Houston','Little_Rock', 'Manchester', 'Maryland', 'Pasadena', 'Phoenix', 'Pomona', 'Salt_Lake_City', 'Saskatoon', 'St_Louis', 'Syracuse', 'Vancouver', 'Wilmington', 'Urbana', 'Mexico')
#city <- c('Vancouver', 'Wilmington', 'Urbana')
#city <- c('Little_Rock', 'Manchester', 'Maryland', 'Pasadena', 'Phoenix', 'Pomona', 'Salt_Lake_City', 'Saskatoon', 'St_Louis', 'Syracuse', 'Vancouver', 'Wilmington', 'Urbana')
#city <- c('Toronto', 'City_of_New_York', 'Atlanta', 'Berkeley', 'Boston', 'Fort_Worth', 'Edmonton', 'Fort_Collins', 'Houston')
#city <- c('Toronto', 'City_of_New_York', 'Fort_Collins') 
#city <- c('Toronto')
#city <- c('Toronto','Peterborough')
#city <- c('Chicago', 'Boston')
#city <- c('City_of_New_York')
#city <- c('City_of_New_York', 'Chicago')
#city <- c('Fort_Collins')
#city <- c('City_of_New_York', 'Fort_Collins', 'Chicago')
city <- c('Peterborough')
#city <- c('Peterborough', 'Brantford')


# SQL code to create city specific urban features.

#view_table <- read.csv('misc/reference_all_views.csv', header=TRUE) #PR
view_vector <- view_table$view

pg_views1 <- view_vector ## from previous R document (priority_table generating script)

#sqlList1 <- list()


#===============================================================================
# Generate raster for each layer of each city following priority values - STEP 5
#===============================================================================


#priority_table <- read.csv('misc/priority_table_v1.csv') %>% select(-X)
priority_table_red <- priority_table %>% select(priority, res_LM, res_SM, source_strength)

#k <- 1

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
  ##will we have trouble with waterways set as the same priority as water, maybe we can directly union them in PG as one single view
  df_unique[which(grepl("homeowner's", df_unique$type, fixed=TRUE)),2]<-"homeowners_association"

  df_unique_res <- df_unique %>%
    mutate(priority = case_when(
      df_unique$feature == "industrial"  ~ '1',
      df_unique$feature == "commercial"  ~ '2',
      df_unique$feature == "institutional"  ~  '3',
      df_unique$feature == "residential"  ~  '4',
      df_unique$feature == "landuse_rail"  ~  '5',
      df_unique$feature == "open_green_area"  ~  '6',
      df_unique$feature == "protected_area"  ~  '7', 
      df_unique$feature == "resourceful_green_area"  ~  '8',
      df_unique$feature == "hetero_green_area"  ~  '9', #non_bare_soil
      df_unique$feature == "bare_soil"  ~   '10' , #bare_soil
      df_unique$feature == "dense_green_area"  ~   '11',
      df_unique$feature == "water"  ~   '12', 
      df_unique$feature == "waterways"  ~   '12', ### hope this wont create trouble, they are both supposed to be at the same level
      df_unique$feature == "parking_surface"  ~ '13',
      df_unique$feature == "building"  ~  '14',
      df_unique$feature == "linear_feature_vh_traffic"  ~  '15',
      df_unique$feature == "linear_feature_no_traffic_side"  ~  '16', # sidewalks
      df_unique$feature == "linear_feature_na_traffic"  ~   '17',
      df_unique$feature == "linear_feature_vl_traffic"  ~  '18',
      df_unique$feature == "linear_feature_l_traffic"  ~  '19',
      df_unique$feature == "linear_feature_m_traffic"  ~  '20',
      df_unique$feature == "linear_feature_h_traffic_ls"  ~  '21',
      df_unique$feature == "linear_feature_h_traffic_hs"  ~  '22',
      df_unique$feature == "linear_feature_rail_trams"  ~  '23', # tram_lines
      df_unique$feature == "linear_feature_no_traffic" ~  '24', # except sidewalks
      df_unique$feature == "linear_feature_rail"  ~  '25',
      df_unique$feature == "linear_feature_rail_abandoned"  ~  '26',
      df_unique$feature == "barrier"  ~  '27'))
  
  df_unique_res$class <- df_unique_res$priority
  #View(df_unique_res)
  df_unique_res$priority<-as.numeric(df_unique_res$priority)
  
 
  df1 <- df_unique_res[,c('feature', 'type', 'view', 'priority')]
  priority_table_red$priority <- as.numeric(priority_table_red$priority)
  # remove duplicates 
  df1 <- df1[!duplicated(df1), ]
  
  #add resistance values in the priority_Table
  df1 <- left_join(df1, priority_table_red, by='priority')
  
  
  # large_mammals (Only need to create land cover with largeMam or smallMam but not both as they both have the same class values)
  df1 <- df1[!is.na(df1$priority),]
  
  largeMam <- df1 %>% select("feature", "type", "view", "priority") # We should call this largeMam obj something else to avoid confusion
  
  featUrb <- unique(df1$view) 
  
  # To save list of features of each city
  #dir.create(paste0(outF, "/", city[k],"/","misc"))
  
  #saveRDS(df1, paste0(outF, "/", city[k],"/","misc", "/","df1"))
  
  
  
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
dbDisconnect(con_pg)


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


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken


# disconnect from db
#dbDisconnect(con_pg)



