
rij_clip <- function(data_rij, pu_rij) {
  combined <- rbind(data_rij, pu_rij)
  intersecting_cols <- combined[, combined["AOI", ] > 0]
  intersecting_rows <- intersecting_cols[Matrix::rowSums(intersecting_cols) > 0, ]
  intersecting_rows
}

rij_to_raster <- function(
    ncc_1km_idx, 
    rij_data_clipped, 
    pu_1km_ext,
    output_folder,
    prefix,
    datatype,
    verbose = TRUE
  ) {
  
  # Identify data rows (excluding AOI and Idx)
  exclude_rows <- c("AOI", "Idx")
  data_rows <- setdiff(rownames(rij_data_clipped), exclude_rows)
  
  if (length(data_rows) == 0) {
    if (verbose) message("No pixels from this layer intersect the AOI")
    return(invisible(NULL))
  }
  
  # Get spatial index from "Idx" row
  idx <- rij_data_clipped["Idx", ]
  
  for (i in seq_along(data_rows)) {
    
    source <- toupper(gsub("_", " ", basename(output_folder)))
    name <- data_rows[i]
    if (verbose) message(paste0(source, " - ", i, " of ", length(data_rows), ": ", name))
    
    r <- ncc_1km_idx
    terra::values(r)[idx] <- rij_data_clipped[name, ]
    names(r) <- name
    
    # get output file name
    filename <- file.path(output_folder, paste0(prefix, name, ".tif"))
    
    # crop
    terra::crop(
      x = r,
      y = pu_1km_ext,
      filename = filename,
      overwrite = TRUE,
      datatype = datatype
    )
  }
}
