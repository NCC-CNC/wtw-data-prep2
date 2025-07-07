
# aoi to 1km grid
create_1km_grid <- function(aoi_sf, grid_template_path) {
  
  # Read-in index
  idx <- terra::rast(grid_template_path) 
  
  # Project to Canada_Albers_WGS_1984
  aoi <- sf::st_transform(aoi_sf, crs = sf::st_crs(idx)) 
  
  # Rasterize boundary polygon: 4700 rows, 5700 cols, 26790000 cells
  pu_1km <- aoi |>
    dplyr::mutate(BURN = 1) |> 
    sf::st_buffer(1000) |> # buffer by 1km
    terra::rasterize(idx, "BURN")
  
  # Raster 1km grid, cell values are NCC indexes, mask values to aoi
  r_pu <- terra::mask((pu_1km * idx), terra::vect(aoi)) 
  
  # Vector 1km grid
  v_pu <- sf::st_as_sf(terra::as.polygons(r_pu)) |>
    dplyr::rename(NCCID = BURN) |>
    dplyr::mutate(PUID = dplyr::row_number()) 
  
  # Create raster template matching vector grid extent
  r_pu_template <- terra::rast(
    terra::vect(v_pu), res = 1000
  )
  
  # Rasterize vector grid, values are all 1
  r_pu <- terra::rasterize(
    terra::vect(v_pu), r_pu_template, 1)
  
  return(list(aoi = aoi, vector_grid = v_pu, raster_grid = r_pu))
}