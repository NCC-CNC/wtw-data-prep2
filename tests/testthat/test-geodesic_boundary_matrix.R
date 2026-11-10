source(file.path("..", "..", "R", "fct_geodesic_boundary_matrix.R"))

# lat/long raster with some NA cells, at Canadian latitudes. 0.25 degree
# cells so vertices are exact in binary; terra::sharedPaths() (used by the
# reference) misses shared edges when vertex coordinates are inexact.
make_lonlat_raster <- function() {
  r <- terra::rast(
    nrows = 6, ncols = 5, xmin = -100, xmax = -98.75, ymin = 49, ymax = 50.5,
    crs = "EPSG:4326"
  )
  terra::values(r) <- seq_len(terra::ncell(r))
  r[c(1, 8, 30)] <- NA
  r
}

# reference: prioritizr's sf method on the cells as polygons, which uses
# terra::perim() (geodesic metres for lat/long). Returned in raster cell order.
reference_boundary_matrix <- function(r) {
  cells <- terra::cells(r)
  p <- sf::st_as_sf(terra::as.polygons(r, aggregate = FALSE, values = FALSE))
  bm <- prioritizr::boundary_matrix(p)
  out <- Matrix::sparseMatrix(
    i = integer(0), j = integer(0), x = numeric(0),
    dims = rep(terra::ncell(r), 2)
  )
  out[cells, cells] <- as.matrix(bm)
  out
}

test_that("geodesic_boundary_matrix matches geodesic polygon perimeters", {
  r <- make_lonlat_raster()
  bm <- geodesic_boundary_matrix(r)
  ref <- reference_boundary_matrix(r)
  expect_s4_class(bm, "dsCMatrix")
  expect_equal(dim(bm), rep(terra::ncell(r), 2))
  expect_equal(as.matrix(bm), as.matrix(ref), tolerance = 1e-6)
})

test_that("geodesic_boundary_matrix returns metres, not degrees", {
  r <- make_lonlat_raster()
  bm <- geodesic_boundary_matrix(r)
  # 0.25 degree cells: ~27.8 km tall; ~17.8 km wide at 50.25N
  expect_equal(bm[2, 3], 27.8e3, tolerance = 0.01)
  expect_equal(bm[2, 7], 17.8e3, tolerance = 0.01)
  # cells further south are wider
  expect_gt(bm[22, 27], bm[2, 7])
})

test_that("geodesic_boundary_matrix excludes NA cells and uses all layers", {
  r <- make_lonlat_raster()
  bm <- geodesic_boundary_matrix(r)
  expect_equal(bm[1, 1], 0)
  expect_equal(bm[1, 2], 0)
  expect_equal(bm[8, 8], 0)
  # a cell NA in layer 1 but not layer 2 is included
  r2 <- c(r, terra::setValues(r, 1))
  bm2 <- geodesic_boundary_matrix(r2)
  expect_gt(bm2[1, 1], 0)
  expect_gt(bm2[1, 2], 0)
})

test_that("geodesic_boundary_matrix rejects projected rasters", {
  r <- terra::rast(
    nrows = 2, ncols = 2, xmin = 0, xmax = 2000, ymin = 0, ymax = 2000,
    crs = "EPSG:3347", vals = 1
  )
  expect_error(geodesic_boundary_matrix(r))
})
