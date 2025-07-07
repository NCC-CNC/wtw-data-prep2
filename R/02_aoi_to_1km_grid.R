
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
