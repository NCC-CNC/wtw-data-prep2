#' Builds a Complete WTW Project: __pipeline__.R
#'
#' This script automates the process of creating a WTW project
#' from start to finish. It performs the following steps:
#'
#' 00. Sets up the environment and loads required packages.
#' 01. Initializes the project folder structure.
#' 02. Transforms the Area of Interest (AOI) shapefile into a 1km grid.
#' 03. Extracts 1km national datasets and aligns them to the project grid.
#' 04. Builds WTW project metadata.
#' 05. Constructs the final WTW project files:
#'     - configuration.yaml
#'     - spatial.tif
#'     - attribute.csv.gz
#'     - boundary.csv.gz
#'
#' @note Ensure that your `setup.toml` `[local]` and `[wtw]` paths are correctly
#' set, and that the WTW project directory is initialized with your `aoi.shp`
#' copied over.
#'
#' This script is intended to be run from an `.Rproj` file that has access to
#' the scripts in your WTW project's `R/` directory.
#'
#' Follow the Where To Work Data Prep User Guide for detailed instructions.
#'
#' Author: Dan Wismer, Data Specialist, Data and Analytics, IT
#' -----------------------------------------------------------------------------

# Start timer
start_time <- Sys.time()

# 00 Set up
source("R/00_setup.R")
print("00 Setup ...")
configs <- setup()
terra::gdalCache(size = 8000) # Set GDAL cache size to 8GB
prep_paths <- configs$paths
wtw <- configs$wtw

# 01 Initialize project folder ----
source("R/01_init_project_folder.R")
print("01 Intalizing project folder ...")
init_project_folder(
  project_dir = prep_paths$project_dir
)

# 02 Build 1km grid ----
source("R/02_aoi_to_1km_grid.R")
print("02 Transforming AOI to 1km grid...")
aoi_to_grid(
  natdata_dir = prep_paths$natdata_dir,
  project_dir = prep_paths$project_dir,
  aoi_shp = prep_paths$aoi_shp
)

# 03 Pull 1km datasets ----
source("R/03_natdata.R")
print("03 Extracting 1km National data...")
natdata(
  natdata_dir = prep_paths$natdata_dir,
  project_dir = prep_paths$project_dir
)

# 04 Build WTW project metadata ----
source("R/04_metadata.R")
print("04 Building Metadata...")
create_wtw_metadata(
  natdata_dir = prep_paths$natdata_dir,
  project_dir = prep_paths$project_dir
)

# 05 Build WTW project ----
source("R/05_wtw.R")
print("05 Building WTW project...")
build_wtw_project(
  project_dir = prep_paths$project_dir,
  punits = prep_paths$punits,
  wtw_metadata = prep_paths$wtw_metadata,
  author = wtw$author,
  email = wtw$email,
  groups = wtw$groups,
  project_name = wtw$project_name,
  file_name = wtw$file_name
)

# End timer
end_time <- Sys.time()
end_time - start_time
