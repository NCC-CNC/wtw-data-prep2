source("fct_install_required_packages.R")

# Define function
extract_raster <- function(
    path_to_poly, path_to_raster, stat, col_name, path_to_temp, 
    cell_value = NULL, csv=NULL) {
  
  # Required R packages
  required_pkgs <- c("terra", "sf", "dplyr", "exactextractr")
  install_required_packages(required_pkgs)  
  
  # Read-in polygon
  poly <- sf::st_read(path_to_poly, quiet = TRUE)
  
  # Set global flags for exact extract
  coverage_area = FALSE
  include_cell = FALSE
  include_cols = c("")
  
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
      
      ### add extracted values as new column, round to 4 decimal places
      poly[[batch_df$short_name[i]]] <- as.numeric(round(vals[[1]], 4))
      
    }
    
  } else {
    
    # ---- ONE-OFF MODE ----
    
    ## read-in raster
    r <- terra::rast(path_to_raster)
    
    if(stat == "area") {
      stat = NULL
      coverage_area = TRUE
      include_cell = TRUE
      include_cols = c("WTWID")
      
      # re project polygon to match raster CRS
      if (sf::st_crs(poly) != sf::st_crs(r)) {
        print("Reprojecting input polygon to match raster.")
        poly <- sf::st_transform(poly, sf::st_crs(r))
      }
    }
    
    # -- EXTRACTIONS (ZONAL STATISTICS) ---
    print("Extracting raster values to polygon.")
    vals <- exactextractr::exact_extract(
      x = r, 
      y = poly, 
      fun = stat,
      include_cell = include_cell,
      coverage_area = coverage_area,
      include_cols = include_cols,
      force_df = TRUE
    )
    
    if(is.null(stat)) { 
      # -- WORKFLOW FOR AREA ---  
      ##  filter each polygon's df for the target cell value
      filtered_list <- lapply(vals, function(df) df[df$value == cell_value, ])
      result_df <- dplyr::bind_rows(filtered_list)
      
      ## summarize per polygon
      summary_df <- result_df |>
        dplyr::group_by(WTWID) |>
        dplyr::summarize(coverage_area_sum = sum(coverage_area, na.rm = TRUE))
      
      ## join extraction df to poly by WTWID
      ## assuming raster is in m2, convert to ha
      poly <- poly |>
        dplyr::left_join(summary_df, by = "WTWID") |>
        dplyr::mutate(coverage_area_sum = ifelse(is.na(coverage_area_sum), 0, coverage_area_sum)) |>
        dplyr::mutate(coverage_area_sum = round((coverage_area_sum / 10000), 2)) # Convert m2 to hectares 
        
      # Rename the column
      names(poly)[names(poly) == "coverage_area_sum"] <- col_name

    } else {
      # -- ALL OTHER STATS --- 
      ## add extracted values as new column, round to 4 decimal places
      poly[[col_name]] <- round(vals[[1]], 4)
    }
  }

  # Write to temp location
  write.csv(
    x = sf::st_drop_geometry(poly), 
    file = file.path(path_to_temp, "r_extract.csv"), 
    row.names = FALSE,
    quote = FALSE
  )
}
