#' Export National Data that intersects Planning Units
#'
#' Reads WTW prep metadata and aligns pu_1km.tif to the canada-wide planning unit
#' grid. For each active dataset, "clips" it to the AOI, and exports the layer
#' as TIF to the WTW project directory, using
#' [constechr::extract_wtw_natdata()].
#'
#' @param natdata_dir Character. Path to the national data directory containing
#'   the `_1km` raster template and WTW metadata CSV (`WTW_NAT_PREP_METADATA.csv`).
#'
#' @param project_dir Character. Path to the project directory containing the AOI
#'   planning unit raster (`pu_1km.tif`) and destination folders for output TIFs.

#' @return Side effects: writes national data to the `/tifs` WTW project folder,
#'   and the aligned planning units to `aoi/pu_1km_align.tif`.
#'
#' @seealso [constechr::extract_wtw_natdata()]
#'
#' -----------------------------------------------------------------------------

natdata <- function(natdata_dir, project_dir) {

  # Extract active national data to tifs/<path>/<prefix><name>.tif
  tifs <- constechr::extract_wtw_natdata(
    natdata_dir = natdata_dir,
    project_dir = project_dir,
    align_file = "aoi/pu_1km_align.tif"
  )

  invisible(tifs)
}
