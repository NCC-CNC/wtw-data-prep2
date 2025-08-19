crs_match <- function(poly, r) {
  crs_poly <- sf::st_crs(poly)
  crs_r    <- sf::st_crs(r)
  
  # 1. Check proj4string first
  if (!is.null(crs_poly$proj4string) && !is.null(crs_r$proj4string)) {
    if (crs_poly$proj4string == crs_r$proj4string) {
      return(TRUE)
    }
  }
  
  # 2. Check EPSG
  if (!is.na(crs_poly$epsg) && !is.na(crs_r$epsg)) {
    if (crs_poly$epsg == crs_r$epsg) {
      return(TRUE)
    }
  }
  
  # 3. Check WKT
  if (!is.na(crs_poly$wkt) && !is.na(crs_r$wkt)) {
    if (crs_poly$wkt == crs_r$wkt) {
      return(TRUE)
    }
  }
  
  # If none matched
  return(FALSE)
}