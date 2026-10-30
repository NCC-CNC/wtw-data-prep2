source_pipeline("02_aoi_to_1km_grid.R")

# See helper-fixtures.R for the hand-worked grid. The AOI is written in
# EPSG:3978 and reprojected by step 02 to the template's CRS.

NATDATA_02 <- make_natdata()

# A project folder with only the AOI shapefile in aoi/
aoi_project <- function(two = FALSE) {
  project_dir <- new_temp_dir("project")
  write_fixture_aoi(file.path(project_dir, "aoi"), two = two)
  project_dir
}

run_aoi_to_grid <- function(project_dir) {
  suppressMessages(aoi_to_grid(
    natdata_dir = NATDATA_02,
    project_dir = project_dir,
    aoi_shp = "fixture_aoi.shp"
  ))
}

PROJECT_02 <- aoi_project()
run_aoi_to_grid(PROJECT_02)

# --- aoi.shp -----------------------------------------------------------------

test_that("aoi.shp is the one AOI feature, attributes kept, in the template CRS", {
  aoi <- sf::read_sf(file.path(PROJECT_02, "aoi", "aoi.shp"))

  expect_equal(nrow(aoi), 1)
  expect_identical(aoi$region, "Fixture")
  expect_identical(
    as.character(sf::st_geometry_type(aoi)), "POLYGON"
  )
  expect_true(terra::same.crs(terra::vect(aoi), fixture_template()))
  expect_equal(
    as.numeric(sf::st_bbox(aoi)),
    c(601300, 1506300, 603600, 1508800),
    tolerance = 1e-6
  )
})

# --- pu_1km.shp --------------------------------------------------------------

test_that("pu_1km.shp has the expected NCCID and PUID values in order", {
  pu <- sf::read_sf(file.path(PROJECT_02, "aoi", "pu_1km.shp"))

  expect_identical(names(pu), c("NCCID", "PUID", "geometry"))
  expect_identical(pu$NCCID, c(62L, 63L, 64L, 72L, 73L))
  expect_identical(pu$PUID, 1:5)
  expect_true(terra::same.crs(terra::vect(pu), fixture_template()))

  # each polygon is its 1 km cell: cells 32 33 34 22 23
  bboxes <- t(vapply(sf::st_geometry(pu), function(g) {
    as.numeric(sf::st_bbox(g))
  }, numeric(4)))
  expect_equal(
    bboxes,
    rbind(
      c(601000, 1506000, 602000, 1507000),
      c(602000, 1506000, 603000, 1507000),
      c(603000, 1506000, 604000, 1507000),
      c(601000, 1507000, 602000, 1508000),
      c(602000, 1507000, 603000, 1508000)
    )
  )
})

# --- pu_1km.tif --------------------------------------------------------------

test_that("pu_1km.tif is INT1U 1s on the trimmed planning-unit extent", {
  path <- file.path(PROJECT_02, "aoi", "pu_1km.tif")
  r <- terra::rast(path)

  expect_identical(terra::datatype(r), "INT1U")
  expect_identical(file_nodata(path), 255)
  expect_identical(names(r), "layer")
  expect_identical(dim(r), c(2, 3, 1))
  expect_equal(terra::res(r), c(1000, 1000))
  expect_equal(
    as.vector(terra::ext(r)),
    c(xmin = 601000, xmax = 604000, ymin = 1506000, ymax = 1508000)
  )
  expect_true(terra::same.crs(r, fixture_template()))
  # cells 22 23 24 32 33 34; 24 is NA in the template
  expect_identical(file_values(path), c(1, 1, NA, 1, 1, 1))
})

# --- errors ------------------------------------------------------------------

test_that("a two-feature AOI errors and writes nothing", {
  project_dir <- aoi_project(two = TRUE)
  before <- list.files(project_dir, recursive = TRUE)

  expect_error(run_aoi_to_grid(project_dir), "one feature")

  expect_identical(list.files(project_dir, recursive = TRUE), before)
  expect_false(file.exists(file.path(project_dir, "aoi", "aoi.shp")))
  expect_false(file.exists(file.path(project_dir, "aoi", "pu_1km.shp")))
  expect_false(file.exists(file.path(project_dir, "aoi", "pu_1km.tif")))
})
