#!/bin/bash
#SBATCH --account=def-mfortin   # replace this with your own account
#SBATCH --mem-per-cpu=20G      # memory; default unit is megabytes
#SBATCH --time=0-02:00           # time (DD-HH:MM)
#SBATCH --cpus-per-task=2
#SBATCH --job-name=urfts2-rast
#SBATCH --output=%x-%j.out

module load gcc/9.3.0 r/4.1.0 geos/3.9.1 gdal/3.2.3 proj/7.2.1 postgresql/12.4  # Adjust version and add the gcc mod>

#Rscript ~/projects/def-mfortin/georod/scripts/mcsc/R/raster_layers_to_lcover_v1.R
Rscript ~/projects/def-mfortin/georod/scripts/mcsc/R/raster_layers_to_lcover_esa_v1.R



