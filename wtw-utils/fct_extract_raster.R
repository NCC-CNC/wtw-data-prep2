source("fct_install_required_packages.R")
source("fct_crs_match.R")

# Define function
extract_raster <- function(
    path_to_poly, path_to_raster, stat, col_name, path_to_temp, 
    cell_value = NULL, csv=NULL) {
  
  # Required R packages
  required_pkgs <- c("terra", "sf", "dplyr", "exactextractr")
  install_required_packages(required_pkgs)  
  
  # Read-in polygon
  poly <- sf::st_read(path_to_poly, quiet = TRUE) # used to extract
  poly_df <- sf::st_drop_geometry(poly) |> # used to store data
    dplyr::select(WTWID)
  
  # Build input table
  if (csv == "") {
    input_df <- data.frame(
      conversion_ready_input = path_to_raster,
      short_name = col_name,
      stat = stat,
      cell_value = ifelse(is.null(cell_value), NULL, cell_value),
      stringsAsFactors = FALSE
    )    
  } else {
    input_df <- read.csv(csv, stringsAsFactors = FALSE) |>
      dplyr::filter(datatype == "raster")
  }  

  # Set global flags for exact extract
  coverage_area = FALSE
  include_cell = FALSE
  include_cols = c("")
  
  # --- EXTRACTION LOOP ---
  for (i in seq_len(nrow(input_df))) {
    
    ## set global flags for exact extract
    coverage_area = FALSE
    include_cell = FALSE
    include_cols = NULL
    
    ## get parameters
    file_name <- basename(input_df[i, "conversion_ready_input"])
    r <- terra::rast(input_df[i, "conversion_ready_input"])
    stat <- input_df[i, "stat"]
    stat_print <- stat # needed for printing
    col_name <- input_df[i, "short_name"]
    cell_value <- input_df[i, "cell_value"]
    
    ## -- AREA PARAMS -- 
    if (stat == "area") {
      stat <- NULL
      coverage_area <- TRUE
      include_cell <- TRUE
      include_cols <- c("WTWID")
    }
      
    # re project polygon to match raster CRS
    is_crs_match <- crs_match(poly, r)
    if (is_crs_match) {
      poly_use <- poly
    } else{
      print(paste0("Reprojecting input polygon to match ", file_name))
      poly_use <- sf::st_transform(poly, sf::st_crs(r))
    }
    
    # -- EXTRACTIONS (ZONAL STATISTICS) ---
    print(paste0("Extracting ", file_name, ": ", stat_print))
    vals <- exactextractr::exact_extract(
      x = r, 
      y = poly_use, 
      fun = stat,
      include_cell = include_cell,
      coverage_area = coverage_area,
      include_cols = include_cols,
      force_df = TRUE,
      progress = FALSE
    )
    
    ## join extractions to polygon
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
      poly_df <- poly_df |>
        dplyr::left_join(dplyr::select(summary_df, WTWID, coverage_area_sum), by = "WTWID") |>
        dplyr::mutate(coverage_area_sum = ifelse(is.na(coverage_area_sum), 0, coverage_area_sum)) |>
        dplyr::mutate(coverage_area_sum = round((coverage_area_sum / 10000), 2)) # Convert m2 to hectares 
      
      # Rename the column
      names(poly_df)[names(poly_df) == "coverage_area_sum"] <- col_name
      
    } else {
      # -- ALL OTHER STATS --- 
      ## add extracted values as new column, round to 4 decimal places
      poly_df[[col_name]] <- round(vals[[1]], 4)
      poly_df[[col_name]][is.na(poly_df[[col_name]])] <- 0 # replace NA with 0
    }
 }

  # Write to temp location
  write.csv(
    x = poly_df, 
    file = file.path(path_to_temp, "r_extract.csv"), 
    row.names = FALSE,
    quote = FALSE
  )
  
  print("Completed")
}
