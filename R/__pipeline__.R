# Start timer
start_time <- Sys.time()

# Set up
source("R/00_setup.R")
print("00 Setup ...")
configs <- setup()
terra::gdalCache(size = 8000) # Set GDAL cache size to 8GB
prep_paths <- configs$paths
wtw <- configs$wtw

# Initialize project folder ---- 
source("R/01_init_project_folder.R")
print("01 Intalizing project folder ...")
init_project_folder(
  project_dir = prep_paths$project_dir
)

# Build 1km grid ----
source("R/02_aoi_to_1km_grid.R")
print("02 Transforming AOI to 1km grid...")
aoi_to_grid(
  natdata_dir = prep_paths$natdata_dir,
  project_dir = prep_paths$project_dir,
  aoi_shp = prep_paths$aoi_shp
)

# Pull 1km datasets ----
source("R/03_natdata.R")
print("03 Extracting 1km National data...")
natdata(
  natdata_dir = prep_paths$natdata_dir,
  project_dir = prep_paths$project_dir
) 

# Build WTW project metadata ----
source("R/04_metadata.R")
print("04 Building Metadata...")
create_wtw_metadata(
  natdata_dir = prep_paths$natdata_dir,
  project_dir = prep_paths$project_dir
)

# Build WTW project ----
source("R/05_wtw.R")
print("05 Building WTW project...")
build_wtw_project(
  project_dir = prep_paths$project_dir,
  author = wtw$author,
  email = wtw$email,
  groups = wtw$groups,
  project_name = wtw$project_name,
  file_name = wtw$file_name
)

# End timer
end_time <- Sys.time()
end_time - start_time
