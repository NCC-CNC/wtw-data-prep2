source_pipeline("04_metadata.R")

# See helper-fixtures.R for expected_wtw_metadata(). The species workbook
# (WTW_NAT_SPECIES_METADATA.xlsx) is written with openxlsx at test time.

NATDATA_04 <- make_natdata()
PROJECT_04 <- make_project(NATDATA_04)
META_PATH_04 <- "wtw/metadata/wtw-metadata.csv"

# --- wtw-metadata.csv --------------------------------------------------------

test_that("create_wtw_metadata() writes the expected wtw-metadata.csv", {
  skip_if_not_installed("openxlsx")
  project_dir <- copy_dir(PROJECT_04, "project")

  create_wtw_metadata(project_dir = project_dir, natdata_dir = NATDATA_04)

  path <- file.path(project_dir, META_PATH_04)
  expect_true(file.exists(path))
  expect_identical(
    strsplit(readLines(path, n = 1), ",")[[1]],
    paste0(
      "\"",
      c(
        "Type", "Theme", "File", "Name", "Legend", "Values", "Color",
        "Labels", "Unit", "Provenance", "Visible", "Hidden", "Downloadable",
        "Goal"
      ),
      "\""
    )
  )
  expect_identical(read_csv_chr(path), expected_wtw_metadata())
})

test_that("the catalogue is read in full despite its BOM and ' file_name'", {
  catalogue <- file.path(NATDATA_04, "WTW_NAT_PREP_METADATA.csv")
  expect_identical(
    readBin(catalogue, "raw", 3), as.raw(c(0xef, 0xbb, 0xbf))
  )
  expect_match(readLines(catalogue, n = 1), ",short_name, file_name,")

  meta <- constechr::read_natdata_metadata(NATDATA_04, active_only = FALSE)

  expect_identical(nrow(meta), 6L)
  expect_identical(names(meta)[1], "product_id")
  expect_true(all(c("file_name", "wtw_file_name") %in% names(meta)))
  expect_identical(meta$active, c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE))
})

# --- categorical rasters (#23) -----------------------------------------------

test_that("a categorical raster gets its own legend values", {
  skip_if_not_installed("openxlsx")
  project_dir <- copy_dir(PROJECT_04, "project")
  # make the first file listed (the exclude) categorical: its stats must come
  # from the cell values, not the category labels, so the metadata is the
  # same as without categories

  path <- file.path(project_dir, "tifs", "excludes", "E_NAT_Urban_fixture.tif")
  r <- terra::rast(path) * 1
  levels(r) <- data.frame(value = c(0, 1), category = c("no", "yes"))
  terra::writeRaster(r, path, datatype = "INT1U", overwrite = TRUE)
  expect_true(terra::is.factor(terra::rast(path)))

  create_wtw_metadata(project_dir = project_dir, natdata_dir = NATDATA_04)

  expect_identical(
    read_csv_chr(file.path(project_dir, META_PATH_04)),
    expected_wtw_metadata()
  )
})
