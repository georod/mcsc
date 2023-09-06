#============================================================================
# Multi-city structural Connectivity Project - Augment Global Landcover (ESA)
#============================================================================

# 2023-09-04
# Code Authors:
# Tiziana Gelmi-Candusso, Peter Rodriguez

# Main aim: Create ini files fro running omniscape. 
# Notes:
# - 

#start.time <- Sys.time()
#start.time

#===================
# Libraries
#===================

#sessionInfo()
#library(DBI)
#library(RPostgreSQL)
#library(sf)
#library(terra)
#install.packages("sqldf")
#library(foreach)
#library(sqldf)
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
#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/mcsc_proj/mammals/"
#project output on server
#outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/smallmam/"

outF <- "~/projects/def-mfortin/georod/data/mcsc_proj/omniscape/"

#outF <- "C:/Users/Peter R/Documents/PhD/tiziana/mcsc_proj/omniscape/"

#===============================
# files needed to run this
#================================
## might have to ad a path to subfolder data/

# list of cities with OSM ID
city <- read.csv("./misc/mcsc_city_list1.csv")

city <- city[!is.na(city$osm_id),]
city$pg_city <- gsub(" ", "_", city$osm_city)

#city <- city[(city$pg_city %in% c('Chicago')), 6]

#city <- city[(city$pg_city %in% c('Phoenix')), 6]
#city <- city[c(1:4, 6:15, 17:30,32,34:35) ,6] # skip Calgary as it was done manually
city <- city[c( 12, 15, 23, 30, 34) ,6] # skip Calgary 33 as it was done manually
city <- city[c(1:4, 6:15, 17:30,32:35) ,6] # #Skip Freiburg & Aromas. Also Mexico city until I download the tile for Mexico (16).

#city <- c("Chicago", "Toronto", "Calgary")

res_folder <- c("avoider", "adapter", "exploiter")

res_raster <- c("resistance_day", "resistance_night")


# 15km avoiders= 500/51 (15,000 m/1530 m)
# 10km adapters= 335/35 (10,050 m/ 1050 m)
# 5km exploiters= 167/17 (5,010 m/ 510 m)

radii <- c(500, 335, 167)

block_size <- c(51,35, 17)


#---------------------------------
# Create parameter files
#---------------------------------

for (k in 1:length(city)) {
  for (i in 1:length(res_folder))
    for (j in 1:length(res_raster))
                            {
                                {
  dir.create(paste0(outF, city[k], "/" ,res_folder[i], "/output"))

fileConn <- file(paste0(outF, city[k], "/", res_folder[i], "/", "parameters_", res_raster[j], ".ini"), "wb")
writeLines( paste0("[Required arguments]
source_file = /project/6000221/georod/data/mcsc_proj/omniscape/", paste0(city[k], "/", res_folder[i]), "/", "source.tif
resistance_file = /project/6000221/georod/data/mcsc_proj/omniscape/", paste0(city[k], "/", res_folder[i]), "/", res_raster[j],".tif", "
radius = ", radii[i],"
project_name = ", paste0("output", "/", res_raster[j]), "

[General options]
block_size = ", block_size[i],"
source_from_resistance = false
r_cutoff = 5
source_threshold = 1
resistance_is_conductance =  false
calc_normalized_current = true
calc_flow_potential = true
allow_different_projections = false
connect_four_neighbors_only = false
solver = cg+amg

[Resistance reclassification]
reclassify_resistance = false

[Processing options]
parallelize = true
parallel_batch_size = 20
precision = double

[Output options]
write_raw_currmap = true
mask_nodata = true
write_as_tif = true

[Conditional connectivity options]
conditional = false
                      "), fileConn)
close(fileConn)
                }
            }
}


#---------------------------------
# Create Julia files
#---------------------------------


for (k in 1:length(city)) {
  for (i in 1:length(res_folder))
    for (j in 1:length(res_raster))
    {
      {
        dir.create(paste0(outF, city[k], "/" ,res_folder[i]))
        
        fileConn <- file(paste0(outF, city[k], "/", res_folder[i], "/", "run_omniscape_", res_raster[j], ".jl"), "wb")
        writeLines(paste0("cd(\"/project/6000221/georod/data/mcsc_proj/omniscape/", paste0(city[k], "/", res_folder[i]),"/","\");",
"
using Omniscape;
run_omniscape(", paste0("\"parameters_", res_raster[j],".ini\""), 
                      ")"), fileConn)
        close(fileConn)
      }
    }
}


#---------------------------------
# Create bash files
#---------------------------------

#Run this prior to lunhcing julia: export JULIA_NUM_THREADS=8

for (k in 1:length(city)) {
  for (i in 1:length(res_folder))
    for (j in 1:length(res_raster))
    {
      {
        fileConn <- file(paste0(outF, city[k], "/", res_folder[i], "/", "omniscape_", res_raster[j], ".sh"), "wb")

writeLines(paste0("#!/bin/bash
#SBATCH --account=def-mfortin
#SBATCH --mem-per-cpu=2048MB
#SBATCH --time=0-01:30
#SBATCH --cpus-per-task=48
#SBATCH --ntasks=1
#SBATCH --job-name=omniscape1
#SBATCH --output=%x-%j.out
#SBATCH --mail-user=peter.rodriguez@mail.utoronto.ca
#SBATCH --mail-type=ALL
module load gcc/9.3.0 julia/1.8.1

srun hostname -s > hostfile1
sleep 5
julia --machine-file ./hostfile1  /project/6000221/georod/data/mcsc_proj/omniscape/", city[k], "/" , res_folder[i],"/" ,"run_omniscape_", res_raster[j],".jl 1000000000000"), fileConn)

close(fileConn)
      }
    }
}
