#' Create a 1km Planning Unit Grid from an AOI
#'
#' Generates a 1km raster and vector grid within a user-defined Area of 
#' Interest (AOI), based on a raster template from national data. The grids are 
#' written to the WTW project directory.
#'
#' @param natdata_dir Character. Path to the national data directory containing 
#' the 1 km raster template (`_1km/idx.tif`).
#' 
#' @param project_dir Character. Path to the project directory where AOI and 
#' grids will be saved.
#' 
#' @param aoi_shp Character. Filename of the AOI shapefile located in the 
#' `aoi` folder of the project directory.
#' 
#' @return Side effects: writes pu_1km.shp and pu_1km.tif to the `aoi` folder.
#' 
#' @seealso [create_1km_grid()]
#' 
#' -----------------------------------------------------------------------------

# Source function
source("R/fct_create_1km_grid.R")
aoi_to_grid <- function(natdata_dir, project_dir, aoi_shp) {
  
  # Get 1km raster grid template
  grid_template_path <- file.path(natdata_dir, "_1km/idx.tif" )
  
  # Read-in aoi shp
  aoi_sf <- sf::read_sf(file.path(project_dir,"aoi", aoi_shp))
  
  # Create 1km grid
  pu_1km <- create_1km_grid(aoi_sf, grid_template_path)
  
  # Write to disk
  ## AOI
  sf::write_sf(
    pu_1km$aoi, 
    file.path(project_dir, "aoi", "aoi.shp")
  )
  
  ## 1km vector grid
  sf::write_sf(
    pu_1km$vector_grid, 
    file.path(project_dir, "aoi", "pu_1km.shp")
  )
  
  ## 1km raster grid
  terra::writeRaster(
    pu_1km$raster_grid, 
    file.path(project_dir, "aoi", "pu_1km.tif"),
    datatype = "INT1U",
    overwrite = TRUE
  )
  
}
