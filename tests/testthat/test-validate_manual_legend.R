source(file.path("R", "fct_validate_manual_legend.R"))

# Helper: create a single-band SpatRaster with given values
make_raster <- function(values) {
  n <- length(values)
  r <- terra::rast(nrows = n, ncols = 1, vals = values)
  r
}

# --- valid manual legends (no errors) ----------------------------------------

test_that("valid binary legend returns no errors", {
  r <- make_raster(c(0, 1, 0, 1))
  result <- validate_manual_legend(
    r,
    "0, 1",
    "#00000000, #343434",
    "Absent, Present"
  )
  expect_equal(result, character(0))
})

test_that("valid single-value legend returns no errors", {
  r <- make_raster(c(1, 1, 1))
  result <- validate_manual_legend(r, "1", "#756bb1", "Habitat")
  expect_equal(result, character(0))
})

# --- raster values vs metadata Values mismatch -------------------------------

test_that("detects raster values not matching metadata Values", {
  r <- make_raster(c(0, 100, 0, 100))
  result <- validate_manual_legend(
    r,
    "0, 1",
    "#00000000, #343434",
    "Absent, Present"
  )
  expect_length(result, 1)
  expect_match(
    result,
    "raster values are \\{0, 100\\} but wtw-metadata.csv Values has \\{0, 1\\}"
  )
})

test_that("detects raster with single value vs metadata with two", {
  r <- make_raster(c(1, 1, 1))
  result <- validate_manual_legend(
    r,
    "0, 1",
    "#00000000, #343434",
    "Absent, Present"
  )
  expect_length(result, 1)
  expect_match(result, "raster values are \\{1\\} but wtw-metadata.csv Values has \\{0, 1\\}")
})

# --- Color and Labels length mismatches --------------------------------------

test_that("detects Color count mismatch", {
  r <- make_raster(c(0, 1, 0, 1))
  result <- validate_manual_legend(r, "0, 1", "#343434", "Absent, Present")
  expect_length(result, 1)
  expect_match(result, "wtw-metadata.csv: Values has 2 but Color has 1")
})

test_that("detects Labels count mismatch", {
  r <- make_raster(c(0, 1, 0, 1))
  result <- validate_manual_legend(r, "0, 1", "#00000000, #343434", "Present")
  expect_length(result, 1)
  expect_match(result, "wtw-metadata.csv: Values has 2 but Labels has 1")
})

test_that("reports multiple errors at once", {
  r <- make_raster(c(0, 1, 0, 1))
  result <- validate_manual_legend(r, "0, 1", "#343434", "Present")
  expect_length(result, 2)
  expect_match(result[1], "Color")
  expect_match(result[2], "Labels")
})

# --- continuous misclassification --------------------------------------------

test_that("detects manual legend that should be continuous (> 5 unique values)", {
  r <- make_raster(c(0, 10.5, 20.3, 30.1, 40.7, 50.9))
  result <- validate_manual_legend(
    r,
    "0, 1",
    "#00000000, #343434",
    "Absent, Present"
  )
  expect_length(result, 1)
  expect_match(result, "should be 'continuous'")
  expect_match(result, "6 unique values")
})

test_that("5 unique values is still treated as manual", {
  r <- make_raster(c(0, 1, 2, 3, 4))
  result <- validate_manual_legend(
    r,
    "0, 1, 2, 3, 4",
    "#a, #b, #c, #d, #e",
    "A, B, C, D, E"
  )
  expect_equal(result, character(0))
})
