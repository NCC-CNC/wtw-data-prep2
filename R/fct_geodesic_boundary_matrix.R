#' Geodesic boundary matrix for lat/long raster planning units
#'
#' Builds a boundary matrix for a raster in geographic coordinates
#' (lat/long), with lengths in geodesic metres. `prioritizr::boundary_matrix()`
#' uses the cell resolution as the edge length, which gives degrees for
#' lat/long rasters.
#'
#' The output follows the same conventions as `prioritizr::boundary_matrix()`:
#' a symmetric `ncell(x)` x `ncell(x)` sparse matrix where off-diagonal values
#' are the length of the edge shared by two adjacent cells, and diagonal values
#' are each cell's total perimeter. Only cells that have a value in at least
#' one layer are included.
#'
#' Each edge length is the geodesic distance between the edge's two corners
#' on the WGS84 ellipsoid (the same calculation `terra::perim()` uses for
#' lat/long polygons). All cells in a raster row have the same edge lengths,
#' so lengths are calculated once per row.
#'
#' @param x `terra::SpatRaster` in a lat/long coordinate reference system.
#'
#' @return `Matrix::dsCMatrix` boundary matrix, in metres.
geodesic_boundary_matrix <- function(x) {
  assertthat::assert_that(
    inherits(x, "SpatRaster"),
    terra::is.lonlat(x)
  )

  # cells with a value in at least one layer
  include <- terra::cells(terra::allNA(x), 0)[[1]]
  x <- terra::setValues(x[[1]], NA_real_)
  x[include] <- 1

  # latitude of each horizontal cell edge, from the top of row 1 to the
  # bottom of the last row (clamped to the poles)
  nr <- terra::nrow(x)
  edge_lat <- terra::ymax(x) - (seq_len(nr + 1) - 1) * terra::yres(x)
  edge_lat <- pmin(pmax(edge_lat, -90), 90)
  xres <- terra::xres(x)

  # horizontal edge lengths: h[k] is the edge at edge_lat[k], so row r has
  # top edge h[r] and bottom edge h[r + 1]
  h <- terra::distance(
    cbind(0, edge_lat), cbind(xres, edge_lat),
    lonlat = TRUE, pairwise = TRUE
  )

  # vertical edge lengths: v[r] is the side edge of row r
  v <- terra::distance(
    cbind(0, edge_lat[-(nr + 1)]), cbind(0, edge_lat[-1]),
    lonlat = TRUE, pairwise = TRUE
  )

  # left-right neighbours share a vertical edge; up-down neighbours share a
  # horizontal edge (the bottom edge of the upper row, i.e. h[lower row])
  lr <- matrix(c(0, 1, 0, 0, 0, 0, 0, 1, 0), 3, 3)
  ud <- matrix(c(0, 0, 0, 1, 0, 1, 0, 0, 0), 3, 3)
  lr_pairs <- terra::adjacent(x, include, pairs = TRUE, directions = lr)
  ud_pairs <- terra::adjacent(x, include, pairs = TRUE, directions = ud)

  b <- rbind(
    data.frame(
      id1 = lr_pairs[, 1],
      id2 = lr_pairs[, 2],
      boundary = v[terra::rowFromCell(x, lr_pairs[, 1])]
    ),
    data.frame(
      id1 = ud_pairs[, 1],
      id2 = ud_pairs[, 2],
      boundary = h[pmax(
        terra::rowFromCell(x, ud_pairs[, 1]),
        terra::rowFromCell(x, ud_pairs[, 2])
      )]
    )
  )
  b$id1 <- as.integer(b$id1)
  b$id2 <- as.integer(b$id2)
  b <- b[(b$id1 %in% include) & (b$id2 %in% include), , drop = FALSE]

  m <- Matrix::forceSymmetric(Matrix::sparseMatrix(
    i = b$id1, j = b$id2, x = b$boundary, dims = rep(terra::ncell(x), 2)
  ))

  # diagonal: total cell perimeter
  r <- terra::rowFromCell(x, include)
  Matrix::diag(m)[include] <- h[r] + h[r + 1] + 2 * v[r]

  methods::as(m, "dsCMatrix")
}
