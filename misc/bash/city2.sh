#!/bin/bash
#SBATCH --account=def-mfortin   # replace this with your own account
#SBATCH --mem-per-cpu=4G      # memory; default unit is megabytes
#SBATCH --time=0-01:00           # time (DD-HH:MM)
#SBATCH --cpus-per-task=3
#SBATCH --job-name=city1
#SBATCH --output=%x-%j.out

module load gcc/9.3.0 r/4.1.0 geos/3.9.1 gdal/3.2.3 proj/7.2.1 postgresql/12.4  # Adjust version and add the gcc mod>

Rscript ~/projects/def-mfortin/georod/scripts/mcsc/R/city_envelopes_squirrels_v1.R


