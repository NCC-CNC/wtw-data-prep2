source("fct_install_required_packages.R")
# Define function
extract_raster <- function(path_to_poly, path_to_raster, stat, col_name, path_to_temp, csv=NULL) {
  
  # Required R packages
  required_pkgs <- c("terra", "sf", "exactextractr")
  install_required_packages(required_pkgs)  
  
  # Read-in polygon
  poly <- sf::st_read(path_to_poly, quiet = TRUE)
  
  # ---- Batch mode ----
  if (!is.null(csv)) {
    
    ## read-in csv
    batch_df <- read.csv(csv, stringsAsFactors = FALSE)
    
    ## extraction loop
    for (i in seq_len(nrow(batch_df))) {
      
      ### read-in raster
      r <- terra::rast(batch_df[i, "conversion_ready_input"])
      
      ### extract raster values
      vals <- exactextractr::exact_extract(
        x = r, 
        y = poly, 
        fun = batch_df[i, "stat"], 
        force_df = TRUE
      )
      
      ### add extracted values as new column
      poly[[batch_df$short_name[i]]] <- vals[[1]]
      
    }
    
  } else {
    
    # ---- One-off mode ----
    
    ## read-in raster
    r <- terra::rast(path_to_raster)
    
    ## extract raster values
    vals <- exactextractr::exact_extract(
      x = r, 
      y = poly, 
      fun = stat, 
      force_df = TRUE
    )
    
    ## add extracted values as new column
    poly[[col_name]] <- vals[[1]]
    
  }

  # Write to temp location
  write.csv(
    sf::st_drop_geometry(poly), 
    file = file.path(path_to_temp, "r_extract.csv"), 
    row.names = FALSE
  )
}
