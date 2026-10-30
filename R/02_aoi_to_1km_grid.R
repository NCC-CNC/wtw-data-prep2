#' Create a 1km Planning Unit Grid from an AOI
#'
#' Generates a 1km raster and vector grid within a user-defined Area of
#' Interest (AOI), based on a raster template from national data. The grids are
#' written to the WTW project directory by
#' [constechr::create_wtw_planning_units()].
#'
#' @param natdata_dir Character. Path to the national data directory containing
#' the 1 km raster template (`_1km/idx.tif`).
#'
#' @param project_dir Character. Path to the project directory where AOI and
#' grids will be saved.
#'
#' @param aoi_shp Character. Filename of the AOI shapefile located in the
#' `aoi` folder of the project directory. The AOI must be a single feature.
#'
#' @return Side effects: writes aoi.shp, pu_1km.shp and pu_1km.tif to the
#' `aoi` folder.
#'
#' @seealso [constechr::create_wtw_planning_units()]
#'
#' -----------------------------------------------------------------------------

aoi_to_grid <- function(natdata_dir, project_dir, aoi_shp) {

  # Create 1km grid and write aoi.shp, pu_1km.shp and pu_1km.tif to disk
  pu_1km <- constechr::create_wtw_planning_units(
    aoi = file.path(project_dir, "aoi", aoi_shp),
    natdata_dir = natdata_dir,
    project_dir = project_dir
  )

  invisible(pu_1km)
}
