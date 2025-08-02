source("R/fct_align_pu.R")
source("R/utils_rij.R")

natdata <- function(natdata_dir, project_dir) {
  
  # Read-in wtw prep metadata, filter for only active data
  wtw_prep_meta <- read.csv(
    file.path(natdata_dir, "WTW_NAT_PREP_METADATA.csv")
  ) |> dplyr::filter(active == TRUE)
  
  # NCC planning units
  grid_template_path <- file.path(natdata_dir, "_1km/idx.tif" )
  ncc_1km <- terra::rast(grid_template_path)
  ncc_1km_idx <- terra::init(ncc_1km, fun="cell") # 267,790,000 pu
  ncc_1km_idx_NA <- terra::init(ncc_1km_idx, fun=NA)
  
  # AOI planning units
  pu_1km_path <- file.path(project_dir, "aoi", "pu_1km.tif")
  pu_1km <- terra::rast(pu_1km_path)
  pu_1km_ext <- terra::ext(pu_1km) 
  
  # align AOI planning units to NCC planning units
  aoi_pu <- align_pu(
    ncc_1km = ncc_1km,
    pu_1km_path = pu_1km_path
  )
  
  # Create pu_rij matrix: 11,010,932 planing units activated 
  pu_rij <- prioritizr::rij_matrix(ncc_1km, c(aoi_pu, ncc_1km_idx))
  rownames(pu_rij) <- c("AOI", "Idx")
  
  # export rij to raster
  for (i in seq_len(nrow(wtw_prep_meta))) {
    row <- wtw_prep_meta[i, ]
    data_path <- file.path(natdata_dir, row$path, row$file_name)
    
    # check if data is a TIF
    if (tools::file_ext(data_path) == "tif") {
      r <- terra::rast(data_path)
      rij_data <- prioritizr::rij_matrix(ncc_1km, r)
      row_name <- tools::file_path_sans_ext(row$file_name)
      rownames(rij_data) <- c(row_name)
    } else {
      rij_data <- readRDS(file.path(data_path))
    }
    
    # intersect data_rij with pu_rij
    rij_data_clipped <- rij_clip(rij_data, pu_rij)
    
    # export rij to raster tif
    rij_to_raster(
      ncc_1km_idx = ncc_1km_idx_NA, 
      rij_data_clipped = rij_data_clipped, 
      pu_1km_ext = pu_1km_ext,
      output_folder = file.path(project_dir, "tifs", row$path),
      prefix = row$prefix,
      datatype = row$datatype,
      verbose = TRUE
    )
    
    # delete objects to save RAM
    rm(rij_data, rij_data_clipped)

  }
}
