
align_pu <- function(ncc_1km, pu_1km_path) {
  
  # Align pu_1km to same extent and same number of rows/cols as national grid ----
  ## get spatial properties of ncc grid
  proj4_string <- terra::crs(ncc_1km,  proj=TRUE) # projection string
  bbox <- terra::ext(ncc_1km) # bounding box
  ### variables for gdalwarp
  te <- c(bbox[1], bbox[3], bbox[2], bbox[4]) # xmin, ymin, xmax, ymax
  ts <- c(terra::ncol(ncc_1km), terra::nrow(ncc_1km)) # ncc grid: columns/rows
  ## gdalUtilities::gdalwarp does not require a local GDAL installation ----
  gdalUtilities::gdalwarp(
    srcfile = pu_1km_path,
    dstfile = paste0(tools::file_path_sans_ext(pu_1km_path), "_align.tif"),
    te = te,
    t_srs = proj4_string,
    ts = ts,
    overwrite = TRUE
  )
  
  # Read-in aligned raster planning units
  pu_1km_aligned <- terra::rast(
    paste0(tools::file_path_sans_ext(pu_1km_path), "_align.tif")
  )
  
  return(pu_1km_aligned)
}