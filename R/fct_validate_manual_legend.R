#' Validate manual legend metadata against raster unique values
#'
#' For a raster with a manual legend, checks that:
#' - The actual unique raster values match the Values listed in metadata.
#' - The number of Color and Labels entries match the number of Values.
#'
#' @param raster A SpatRaster object.
#' @param values Character. Comma-separated values string from metadata.
#' @param colors Character. Comma-separated color string from metadata.
#' @param labels Character. Comma-separated labels string from metadata.
#'
#' @return A character vector of mismatch descriptions, or `character(0)` if
#'   everything matches.
#'
validate_manual_legend <- function(raster, values, colors, labels) {
  meta_values <- as.numeric(trimws(unlist(strsplit(as.character(values), ","))))
  n_colors <- length(trimws(unlist(strsplit(as.character(colors), ","))))
  n_labels <- length(trimws(unlist(strsplit(as.character(labels), ","))))
  raster_values <- sort(terra::unique(raster, na.rm = TRUE)[[1]])

  legend_errors <- character(0)
  n_raster <- length(raster_values)

  # If raster has many unique values, it should be continuous not manual
  if (n_raster > 5) {
    return(sprintf(
      "Legend is 'manual' but raster has %d unique values — should be 'continuous'",
      n_raster
    ))
  }

  # Check that raster values match metadata Values
  if (!identical(sort(meta_values), raster_values)) {
    legend_errors <- c(
      legend_errors,
      sprintf(
        "raster values are {%s} but wtw-metadata.csv Values has {%s}",
        paste(raster_values, collapse = ", "),
        paste(sort(meta_values), collapse = ", ")
      )
    )
  }

  # Check Color and Labels length against Values
  if (length(meta_values) != n_colors) {
    legend_errors <- c(
      legend_errors,
      sprintf("wtw-metadata.csv: Values has %d but Color has %d", length(meta_values), n_colors)
    )
  }
  if (length(meta_values) != n_labels) {
    legend_errors <- c(
      legend_errors,
      sprintf("wtw-metadata.csv: Values has %d but Labels has %d", length(meta_values), n_labels)
    )
  }
  legend_errors
}
