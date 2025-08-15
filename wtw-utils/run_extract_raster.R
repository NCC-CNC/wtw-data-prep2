#!/usr/bin/env Rscript
source("fct_extract_raster.R")

# Read command-line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 5) {
  stop("At least 5 arguments required: path_to_poly, path_to_raster, stat, col_name, path_to_temp, [cell_value], [csv]")
}

# Assign mandatory arguments
path_to_poly   <- args[1]
path_to_raster <- args[2]
stat           <- args[3]
col_name       <- args[4]
path_to_temp   <- args[5]

# Optional arguments
cell_value <- NULL
csv        <- NULL

# args[6] = cell_value (optional)
if (length(args) >= 6) {
  cell_value <- as.numeric(args[6])
}

# args[7] = csv (optional)
if (length(args) >= 7) {
  csv <- args[7]
}

# Run function
extract_raster(path_to_poly, path_to_raster, stat, col_name, path_to_temp, cell_value, csv)