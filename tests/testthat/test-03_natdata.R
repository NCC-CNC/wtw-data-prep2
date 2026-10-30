source_pipeline(c(
  "01_init_project_folder.R", "02_aoi_to_1km_grid.R", "03_natdata.R"
))

# See helper-fixtures.R for the hand-worked layers and expected_tifs()

NATDATA_03 <- make_natdata()
PROJECT_03 <- new_temp_dir("project")
suppressMessages({
  init_project_folder(project_dir = PROJECT_03)
  write_fixture_aoi(file.path(PROJECT_03, "aoi"))
  aoi_to_grid(
    natdata_dir = NATDATA_03,
    project_dir = PROJECT_03,
    aoi_shp = "fixture_aoi.shp"
  )
})
MESSAGES_03 <- testthat::capture_messages(
  natdata(natdata_dir = NATDATA_03, project_dir = PROJECT_03)
)
TIF_DIR_03 <- file.path(PROJECT_03, "tifs")

# --- layer files -------------------------------------------------------------

test_that("natdata() writes exactly tifs/<path>/<prefix><name>.tif", {
  expect_setequal(
    list.files(TIF_DIR_03, recursive = TRUE),
    names(expected_tifs())
  )
})

test_that("each layer has the catalogue's data type, NoData and values", {
  pu <- terra::rast(file.path(PROJECT_03, "aoi", "pu_1km.tif"))
  for (f in names(expected_tifs())) {
    expected <- expected_tifs()[[f]]
    path <- file.path(TIF_DIR_03, f)
    r <- terra::rast(path)
    expect_identical(terra::datatype(r), expected$datatype, label = f)
    expect_identical(file_nodata(path), expected$nodata, label = f)
    expect_identical(terra::nlyr(r), 1, label = f)
    expect_true(terra::compareGeom(r, pu, stopOnError = FALSE), label = f)
    expect_identical(file_values(path), expected$values, label = f)
  }
})

test_that("layer band names are the feature names, without prefix", {
  band <- function(f) names(terra::rast(file.path(TIF_DIR_03, f)))
  expect_identical(band("excludes/E_NAT_Urban_fixture.tif"), "Urban_fixture")
  expect_identical(
    band("themes/habitat/T_NAT_HABITAT_Forest_fixture_ha.tif"),
    "Forest_fixture_ha"
  )
  # rij rows are named in full; ECCC_CH has no prefix
  expect_identical(
    band("themes/species/eccc_ch/T_NAT_ECCC_CH_SPA.tif"),
    "T_NAT_ECCC_CH_SPA"
  )
})

test_that("the empty feature and the inactive layer are not written", {
  expect_false(file.exists(
    file.path(TIF_DIR_03, "themes/species/eccc_ch/T_NAT_ECCC_CH_SPD.tif")
  ))
  expect_false(file.exists(
    file.path(TIF_DIR_03, "weights/climate/W_NAT_Climate_fixture.tif")
  ))
  expect_length(list.files(file.path(TIF_DIR_03, "weights", "climate")), 0)
  # the dropped feature is named in a message; the inactive layer isn't read
  expect_true(any(grepl("T_NAT_ECCC_CH_SPD", MESSAGES_03)))
  expect_false(any(grepl("Climate_fixture", MESSAGES_03)))
})

# --- pu_1km_align.tif --------------------------------------------------------

test_that("pu_1km_align.tif is the planning units on the template's grid", {
  path <- file.path(PROJECT_03, "aoi", "pu_1km_align.tif")
  expect_true(file.exists(path))
  r <- terra::rast(path)

  expect_true(terra::compareGeom(r, fixture_template(), stopOnError = FALSE))
  expect_equal(
    as.vector(terra::ext(r)),
    c(xmin = 600000, xmax = 610000, ymin = 1500000, ymax = 1510000)
  )
  expect_identical(terra::datatype(r), "INT1U")
  expect_identical(file_nodata(path), 255)
  expect_identical(names(r), "layer")
  expected <- rep(NA_real_, 100)
  expected[c(22, 23, 32, 33, 34)] <- 1
  expect_identical(file_values(path), expected)
})
