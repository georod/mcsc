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
library(ggpubr)

#===============================
# files needed to run this
#================================
## might have to ad a path to subfolder data/

# list of cities with OSM ID
city <- read.csv("mcsc_city_list1.csv")
# table with all the views we create with PG admin
view_table <- read.csv('reference_all_views.csv', header=FALSE)
# table with the priority, resistance and source strength
priority_table <- read.csv('priority_table_v1.csv')
resTab <- read.csv("priority_table_v1.csv")
#tables with the classes included in the Global landcover and their equivalence to our OSM-derived landcover classes
cec <- read.csv('cec_north_america.csv')
cop <- read.csv('copernicus_reclassification_table.csv') 
#rec_cec_final <- read.csv('reclass_cec_2_mcsc.csv') #these are objects created within the code but could be called from table 
# rec_cop_final <- read.csv('reclass_copernicus_2_mcsc.csv') #these are objects created within the code but could be called from table

#GBIF mammals including our relevant species, Ungulates, Carnivores, and smaller mammal orders, excluding dogs, follows script in preparing_GBIF_data.R
mammals_all<-read.csv("GBIF_relevant_mammals_data.csv")

#=================================
# Set folder & files paths STEP 1
#=================================
# github project folder on server
setwd("~/projects/def-mfortin/georod/scripts/mcsc/")
# project folder on desktop
#setwd("~/github/mcsc/")
##Tiziana's working directory for this project
#setwd("C:/Users/tizge/Documents/StructuralconnectivityDB/")

# project output folder
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/test2/"
#project output on server
#outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/smallmam/"
#res <- 'res_SM'

## loop creates both resistance maps anyways
outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/largemam/"

##Tiziana's output folder for this project'
#outF <- "C:/Users/tizge/Documents/StructuralconnectivityDB/largemam/"


#=================================
# Connect to PG db STEP 2
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
##Tiziana's db

# con_pg <- DBI::dbConnect(
#   drv = RPostgres::Postgres(),
#   host = "localhost",
#   port = 5432,
#   dbname = "osm",
#   user = "postgres",
#   password = "***")
# # 
#==============================================
# Create city envelopes for each city STEP 3
#==============================================

city <- read.csv("mcsc_city_list1.csv")
city <- city[!is.na(city$osm_id),]
city$pg_city <- gsub(" ", "_", city$osm_city)


for (j in 1:nrow(city)) {
  
  dbSendQuery(con_pg, paste0("DROP TABLE IF EXISTS ", city$pg_city[j],"_env", " CASCADE;"))
  
  #dbSendQuery(con_pg, paste0("CREATE TABLE ", city$pg_city[j],"_env", "  AS SELECT (row_number() OVER ())::int AS sid, relation_id::varchar(20), 'background'::varchar(30) AS feature, tags->>'name'::varchar(30)  AS type, tags ->> 'admin_level'::varchar(30) AS material, '' AS size, st_envelope(st_buffer(st_envelope(st_multi(st_buildarea(geom))), 500))::geometry(Polygon, 3857) AS geom  FROM boundaries WHERE tags->> 'boundary' IN ('administrative') AND tags->> 'name'=","'", city$osm_city[j],"'" , " AND tags ->> 'admin_level'=","'",city$admin_level[j], "';"))
  dbSendQuery(con_pg, paste0("CREATE TABLE ", city$pg_city[j],"_env", "  AS SELECT (row_number() OVER ())::int AS sid, relation_id::varchar(20), 'background'::varchar(30) AS feature, tags->>'name'::varchar(30)  AS type, tags ->> 'admin_level'::varchar(30) AS material, '' AS size, st_envelope(st_buffer(st_envelope(st_multi(st_buildarea(geom))),", city$buffer[j]*1000, "))::geometry(Polygon, 3857) AS geom  FROM boundaries WHERE relation_id=", city$osm_id[j], " ;"))
  
  dbSendQuery(con_pg, paste0("ALTER TABLE ", city$pg_city[j],"_env", " ADD CONSTRAINT ", city$pg_city[j],"_env", "_pkey PRIMARY KEY (sid);"))
  
  dbSendQuery(con_pg, paste0("CREATE INDEX ", city$pg_city[j],"_env", "_geom_idx ON ", city$pg_city[j],"_env",  " USING gist (geom) WITH (FILLFACTOR=100) TABLESPACE pg_default;") )
  
  print(city$pg_city[j])
}


#=========================================================
# Call views for city envelopes - STEP 4
#=========================================================

#select which cities to run
#city <- c('Mexico')
#city <- c('Toronto', 'City_of_New_York', 'Atlanta', 'Berkeley', 'Boston', 'Fort_Worth', 'Edmonton', 'Fort_Collins', 'Houston','Little_Rock', 'Manchester', 'Maryland', 'Pasadena', 'Phoenix', 'Pomona', 'Salt_Lake_City', 'Saskatoon', 'St_Louis', 'Syracuse', 'Vancouver', 'Wilmington', 'Urbana', 'Mexico')
#city <- c('Vancouver', 'Wilmington', 'Urbana')
#city <- c('Little_Rock', 'Manchester', 'Maryland', 'Pasadena', 'Phoenix', 'Pomona', 'Salt_Lake_City', 'Saskatoon', 'St_Louis', 'Syracuse', 'Vancouver', 'Wilmington', 'Urbana')
#city <- c('Toronto', 'City_of_New_York', 'Atlanta', 'Berkeley', 'Boston', 'Fort_Worth', 'Edmonton', 'Fort_Collins', 'Houston')
#city <- c('Toronto', 'City_of_New_York', 'Fort_Collins') 
#city <- c('Toronto')
city <- c('Toronto','Peterborough')
#city <- c('Chicago', 'Boston')
#city <- c('City_of_New_York')
#city <- c('City_of_New_York', 'Chicago')
#city <- c('Fort_Collins')
#city <- c('City_of_New_York', 'Fort_Collins', 'Chicago')
#city <- c('Peterborough')
#city <- c('Peterborough', 'Brantford')

# SQL code to create city specific urban features.

view_table <- read.csv('reference_all_views.csv', header=FALSE)
view_vector <- view_table$view

pg_views1 <- view_vector ## from previous R document (priority_table generating script)

sqlList1 <- list()

##the k here is giving me trouble do we need lines 219 to 242??
for (i in 1:length(pg_views1)){
  sqlList1[i] <- paste0("SELECT t1.feature, CASE WHEN t1.type is null then 'NULL' else t1.type END AS type, t1.material, t1.size::numeric,", "'", pg_views1[i],"'", " AS view FROM ", pg_views1[i], " t1 JOIN ",
                        city[k],"_env", " t2 ON st_intersects(t1.geom,t2.geom)")
  
}

sqlUnion1 <- do.call(paste, c(sqlList1, sep=" UNION ALL ")) 

##if we could add priority here we wouldnt have to make a priority table and add the value ,
#is just that it doesnt let me call it in the query, I tried adding it but it gave me 
#Error: Failed to prepare query: ERROR:  column "pri" does not exist
# LINE 1: ....type END AS type, t1.material, t1.size::numeric, pri,'comme...
#                                                              ^
# HINT:  There is a column named "pri" in table "*SELECT* 1", but it cannot be referenced from this part of the query.

df <- dbGetQuery(con_pg, paste0(
  "SELECT DISTINCT feature, type, material, size, view, row_number() OVER (ORDER BY view, feature) AS rid FROM (", sqlUnion1, ") t1;"))


#===============================================================================
# Generate raster for each layer of each city following priority values STEP 5
#===============================================================================


priority_table <- read.csv('priority_table_v1.csv') %>% select(-X)
priority_table_red <- priority_table %>% select(priority, res_LM, res_SM, source_strength)


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
  
  largeMam <- df1 %>% select("feature", "type", "view", "priority")
  
  featUrb <- unique(df1$view) 
  
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
# Fill in with Land cover raster and extract accuracy, random and GBIF values from raster
#=================================

#local test raster
#r4 <- rast("C:/Users/Peter R/Documents/data/ont_Red.tif")
##using canada CEC for now
r4 <- rast("C:/Users/tizge/Documents/StructuralconnectivityDB/data/cec/CAN_NALCMS_landcover_2015v2_30m.tif")

###reclassification table for CEC
pri <- priority_table %>% select(feature, priority)
colnames(pri)<- c('mcsc', 'mcsc_value')
cec <- read.csv('cec_north_america.csv')
rec_cec <- left_join(cec, pri, by='mcsc')
rec_cec_final <- rec_cec %>% mutate(mcsc_value = ifelse(mcsc == 'developed_na', 28, mcsc_value))
#write.csv(rec_cec_final, 'reclass_cec_2_mcsc.csv')
#rec_cec_final <- read.csv('reclass_cec_2_mcsc.csv')

###reclassification table for copernicus
cop <- read.csv('copernicus_reclassification_table.csv') %>% select (copernicus, value, mcsc)
rec_cop <- left_join(cop, pri, by='mcsc')
rec_cop %>% filter(is.na(mcsc_value)) 
#rec_cop$mcsc[6]<-'linear_feature_na_traffic' 
rec_cop$mcsc[7]<-'linear_feature_na_traffic' 
rec_cop$mcsc[23]<-'linear_feature_vh_traffic'
rec_cop$mcsc[9]<-'linear_feature_rail'   
rec_cop <- rec_cop %>% select(1,2,3)
rec_cop <- left_join(rec_cop, pri, by='mcsc')
rec_cop_final <- rec_cop %>% mutate(mcsc_value= ifelse(mcsc == 'developed_na', 28, mcsc_value))
# write.csv(rec_cop_final, 'reclass_copernicus_2_mcsc.csv')
# rec_cop_final <- read.csv('reclass_copernicus_2_mcsc.csv')
cecRes <- rec_cec_final
#cecRes <- read.csv("./misc/cec_north_america_resistance_values.csv")



resTab <- read.csv("priority_table_v1.csv")
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

###INITIATIAZION PROCESSES
##prepare GBIF_data before entering loop, i.e. read GBIF table, convert values to spatvector for extraction
mammals_all <-read.csv("GBIF_relevant_mammals_data.csv")
mammals_sp <- vect(mammals_all, geom=c("x", "y"), crs=CRS("+init=epsg:4326"))

###INITIAL TABLES NEEDED FOR FOLLOWING LOOP 
coverage_table<- data.frame(city = rep(NA, 1), prop_missing = rep(NA, 1), missing_area = rep(NA, 1), total_area= rep(NA, 1))
coverage_table_classes <-data.frame(class = c(1:28))
coverage_table_classes_vertical <- data.frame()
random_points_all <- data.frame()
hsf_table_all <- data.frame()
    
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
  #plot(raster(r3))
  
  # transform cropped raster crs to EPSG 3857 , "EPSG:3857"
  r6 <- project(r5, r3, method="near", align=TRUE)
  # crop to ensure rasters have the same extent
  r6 <- crop(r6, r3)
  #plot(raster(r7))
  #plot(r6, type="classes")
  # Mask raster
  r7 <- mask(r6, r3, inverse=TRUE, maskvalue=NA)
  
  rclM <- as.matrix(cecRes[,c(2,4)])
  #rclM <- matrix(rclM, ncol=2, byrow=TRUE)
  r8 <- classify(r7, rclM)

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
  
  ##stats: overall missing osm pixels
  missing_cells <- ncell(r3) - global(r3>=1, "sum", na.rm=TRUE)
  proportion_missing <- missing_cells/ncell(r3)
  coverage_table[nrow(coverage_table)+1,1]<- city[k]
  coverage_table[nrow(coverage_table),2]<- proportion_missing$sum
  coverage_table[nrow(coverage_table),3]<- missing_cells$sum
  coverage_table[nrow(coverage_table),4]<- ncell(r3)
  
  coverage_table<-coverage_table %>% filter(!is.na(city))
  # coverage_table<-coverage_table %>% filter(!is.na(prop_missing))
  # 
  ##stats: overall missing osm pixels_per class####
  
  #count cells x class on full raster
  fr9<-as.data.frame(freq(r9))
  colnames(fr9)<-c('N','class', 'count_r9')
  #count cells x class on osm raster
  fr3<-as.data.frame(freq(r3))
  fr3[nrow(fr3)+1,]<-c(1,28,0)
  fr9$count_r3<-fr3$count
  #do the math
  fr9$count_diff <- fr9$count_r9-fr9$count_r3
  fr9$miss_prop <- fr9$count_diff/ncell(r9)
  #add to table
  fr29 <- left_join(coverage_table_classes,fr9, by="class") #in case any classes are missing
  
  ##horizontal table (easy to compare between cities)
  coverage_table_classes$city<-fr29$miss_prop
  names(coverage_table_classes)[names(coverage_table_classes) == 'city'] <- city[k]
  
  ##vertical table for conjunct pie graph
  coverage_table_cla <- data.frame(class = c(1:28))
  fr39 <- left_join(coverage_table_cla,fr9, by="class") #in case any classes are missing
  fr39 <- fr39 %>% select(1,6)
  fr39$city <- city[k]
  fr39<-fr39 %>% mutate(miss_prop = ifelse(is.na(miss_prop),0,miss_prop))
  fr39[nrow(fr39)+1,]<-c('NA',  1-sum(as.numeric(fr39$miss_prop)), city[k])
  
  coverage_table_classes_vertical <- rbind(coverage_table_classes_vertical, fr39) 
  
  ######### extract random data from points###### change number of points on second parameter of spatsample()

  t9<-project(r9,CRS("+init=epsg:4326"), method="near")
  random_points<-spatSample(t9, 10, method="random", replace=FALSE, na.rm=FALSE, 
             as.raster=FALSE, as.df=TRUE, as.points=FALSE, values=TRUE, cells=FALSE, 
             xy=TRUE, ext=NULL, warn=TRUE)
  random_points<-random_points %>% 
    mutate(city = city[k]) %>%
    select(city,y,x,first)
  colnames(random_points)<- c('city', 'lat', 'lon', 'osm_class')
  
  
  #save random points plot for double checking
  random_points_sp <- vect(random_points, geom=c("lon", "lat"), crs=CRS("+init=epsg:4326"))
  r8.1 <- classify(r6, rclM)
  t8<-project(r8.1,CRS("+init=epsg:4326"), method="near")
  
  rp_ex<-terra::extract(t8, random_points_sp, ID=TRUE, weights=FALSE, fun=max, method='simple', bind=TRUE)
  random_points_sp$cec_class <- rp_ex[,-1]
  rp_df <- as.data.frame(random_points_sp)
  ##create city specific table of random points
  write.csv(rp_df, paste0(outF,"lcrasters/",city[k],"/output/","random_points_", city[k],".csv"))
  
  
  
  png(file=paste0(outF,"lcrasters/",city[k],"/output/","RandompointsPlot_", city[k], ".png", sep=""))
    mytitle = paste("Random Points", city[k])
    plot(raster(t9), main = paste("Random Points", city[k]))
    plot(random_points_sp, add=TRUE)
  dev.off()

  ##append to a global table of random points
  random_points_all<-rbind(random_points_all, rp_df)

  
  #########overlay GBIF points #######
  ## call file with points downloaded from GBIF database
  ## crop GBIF spatvector to city
  b<-terra::crop(mammals_sp, t9)
  
  png(file=paste0(outF,"lcrasters/",city[k],"/output/","GBIF_", city[k], ".png", sep=""))
    mytitle = paste("GBIF overlay", city[k])
    plot(raster(t9), main = paste("GBIF overlay", city[k]))
    plot(b, add=TRUE)
  dev.off()
  
  ##extract class values for GBIF points and add them to the mammals_sp spatvector
  b_ex<-terra::extract(t9, b, ID=TRUE, weights=FALSE, fun=max, method='simple', bind=TRUE)
  b$osm_class <- b_ex[,-1]
  b_df <- as.data.frame(b) %>% select(order,family,genus,basisOfRecord,eventDate,x,y,osm_class)
  b_df$city <- city[k]
  
  random_points_GBIF<-spatSample(t9, 1000, method="random", replace=FALSE, na.rm=FALSE, 
                            as.raster=FALSE, as.df=TRUE, as.points=FALSE, values=TRUE, cells=FALSE, 
                            xy=TRUE, ext=NULL, warn=TRUE)
  random_points_GBIF<-random_points_GBIF %>% 
    mutate(city = city[k]) %>%
    select(city,y,x,first)
  colnames(random_points_GBIF)<- c('city', 'y', 'x', 'osm_class')
  random_points_GBIF <- random_points_GBIF %>% 
    mutate(eventDate = "random")%>% 
    mutate(basisOfRecord = "random")%>% 
    mutate(order = "random") %>% 
    mutate(family = "random") %>% 
    mutate(genus = "random") 
  
  hsf_table <- rbind(b_df, random_points_GBIF)
  write.csv(hsf_table, paste0(outF,"lcrasters/",city[k],"/output/","HSF_points_", city[k], ".csv", sep=" "))
  
  hsf_table_all <- rbind(hsf_table_all, hsf_table)
  
  hsf_table_sp <- vect(hsf_table, geom=c("x", "y"), crs=CRS("+init=epsg:4326"))
  png(file=paste0(outF,"lcrasters/",city[k],"/output/","HSF_points_", city[k], ".png", sep=""))
    mytitle = paste("HSF overlay", city[k])
    plot(raster(t9))
    plot(hsf_table_sp, add=TRUE, col=ifelse(hsf_table_sp$genus=='random', 'black','red'))
  dev.off()
}


write.csv(coverage_table, paste0(outF,"lcrasters/",'coverage_table.csv'))
write.csv(coverage_table_classes, paste0(outF,"lcrasters/",'coverage_table_classes_horizontal.csv'))
write.csv(coverage_table_classes_vertical, paste0(outF,"lcrasters/",'coverage_table_classes_vertical.csv'))
write.csv(random_points_all, paste0(outF,"lcrasters/",'random_points_all_cities.csv'))
write.csv(hsf_table_all, paste0(outF,"lcrasters/",'hsf_table_all_cities.csv'))

# disconnect from db
#dbDisconnect(con_pg)


#######################################################
### Plot of osm-missed proportions with all cities ####
#######################################################
library(ggplot2)

coverage_table_classes_vertical$city <- factor(coverage_table_classes_vertical$city) # converts to a categorical variable
coverage_table_classes_vertical$class <- factor(coverage_table_classes_vertical$class, levels=c(c(1:28), "NA")) # converts to a categorical variable
coverage_table_classes_vertical$miss_prop <- as.numeric(coverage_table_classes_vertical$miss_prop) # converts to a categorical variable

sum<-coverage_table_classes_vertical %>% filter(miss_prop>0)
miss_classes<-unique(as.character(sum$class))
miss_c<- data.frame(priority=c(1:length(miss_classes)))
miss_c$priority<-as.factor(miss_classes)
view_table$priority<-factor(view_table$priority)
c<-left_join(miss_c, view_table, by="priority")
c<-c%>% mutate(feature=ifelse(priority==28,'developed_na', feature)) %>%
  mutate(feature=ifelse(priority=="NA",'not_missed', feature)) 
c$priority <- factor(c$priority, levels = c(c(1:28), "NA"))

#colorblind palette
cbp2 <- c("#E69F00", "#56B4E9", "#009E73",
          "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#999999", 
          "#000000", "#E69F00", "#56B4E9", "#009E73",
          "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

coverage_table_classes_vertical$miss_prop <- as.numeric(coverage_table_classes_vertical$miss_prop)
pie<-ggplot(coverage_table_classes_vertical, aes(x = city, y = miss_prop, fill = class)) +
  geom_col() +
  #scale_y_continuous(limits=c(0,1))+
  scale_fill_manual(limits = c$priority, labels=c$feature, values=cbp2) +
  coord_polar("y")+
  scale_y_continuous(name="Class proportion OSM missed")

###########################################
 #how much is OSM missing relative across study areas with different size
###########################################

coverage_table
line<-ggplot(coverage_table, aes(y=prop_missing, x=total_area, fill=city)) +
  geom_point(size=2, shape=21)+ 
  geom_text(label=coverage_table$city, size=2, vjust = 0, nudge_y = 0.01)+
  theme_bw()+
  theme(legend.position="top")+
  scale_y_continuous(name="Overall proporion OSM missed")+
  scale_x_continuous(name="Total study area")

#####combine line graph and pie chart#####
combg <- ggarrange(line, pie, ncol=2,nrow=1, widths = c(0.5, 1))
ggsave(paste0(outF,"lcrasters/","osm_missed_combined.png"), 
       plot=combg,
       width=2400,
       height=800,
       units="px",
       dpi=300,
       limitsize=FALSE)


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken



