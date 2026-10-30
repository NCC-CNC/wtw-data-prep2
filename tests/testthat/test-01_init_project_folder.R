source_pipeline("01_init_project_folder.R")

# The 32 folders of a WTW project, as the pipeline's own
# create_project_folder() made them before constechr
EXPECTED_FOLDERS <- c(
  "aoi",
  "tifs",
  "tifs/themes",
  "tifs/themes/species",
  paste0(
    "tifs/themes/species/",
    c(
      "eccc_ch", "eccc_sar", "iucn_amph", "iucn_bird", "iucn_rept",
      "iucn_mamm", "nsc_end", "nsc_sar", "nsc_spp", "ncc_sdm", "ncc_sar_aoh"
    )
  ),
  "tifs/themes/habitat",
  "tifs/weights",
  paste0(
    "tifs/weights/",
    c(
      "carbon", "climate", "connectivity", "eservices", "pressures",
      "hotspots"
    )
  ),
  "tifs/includes",
  "tifs/excludes",
  "wtw",
  "wtw/metadata",
  "wtw/runs",
  "dataprep",
  "dataprep/national",
  "dataprep/regional",
  "dataprep/tmp"
)

# --- folders -----------------------------------------------------------------

test_that("init_project_folder() creates exactly the 32 project folders", {
  project_dir <- file.path(new_temp_dir("init"), "project")

  suppressMessages(init_project_folder(project_dir = project_dir))

  expect_length(EXPECTED_FOLDERS, 32)
  expect_true(dir.exists(project_dir))
  folders <- list.dirs(project_dir, full.names = FALSE, recursive = TRUE)
  expect_setequal(folders[nzchar(folders)], EXPECTED_FOLDERS)
  # the only file is the dataprep template
  expect_identical(
    list.files(project_dir, recursive = TRUE),
    "dataprep/dataprep.csv"
  )
})

test_that("init_project_folder() keeps existing files in the project", {
  project_dir <- new_temp_dir("init")
  dir.create(file.path(project_dir, "aoi"))
  writeLines("keep", file.path(project_dir, "aoi", "keep.txt"))

  suppressMessages(init_project_folder(project_dir = project_dir))

  expect_identical(readLines(file.path(project_dir, "aoi", "keep.txt")), "keep")
})

# --- dataprep.csv ------------------------------------------------------------

test_that("dataprep.csv has the template's columns and description row", {
  project_dir <- new_temp_dir("init")

  suppressMessages(init_project_folder(project_dir = project_dir))

  path <- file.path(project_dir, "dataprep", "dataprep.csv")
  expect_true(file.exists(path))
  x <- read_csv_chr(path)
  expect_identical(
    x,
    data.frame(
      conversion_ready_input = "full filepath to input data",
      short_name = "10 characters or less name for variable",
      tif_output = "full filepath with extension to output tif",
      unit = "supported units: m2, ha, km2, m, km and count",
      stat = "supported stats: mean, max, min, sum, stdev, mode and area ",
      cell_value = "if stat is area, provide cell value to extract",
      datatype = "supported types: raster, vector",
      provenance = "national or regional",
      stringsAsFactors = FALSE
    )
  )
  # written as write.csv() writes it: every field quoted, no row names
  expect_identical(
    readLines(path),
    c(
      paste0(
        "\"conversion_ready_input\",\"short_name\",\"tif_output\",\"unit\",",
        "\"stat\",\"cell_value\",\"datatype\",\"provenance\""
      ),
      paste0(
        "\"full filepath to input data\",",
        "\"10 characters or less name for variable\",",
        "\"full filepath with extension to output tif\",",
        "\"supported units: m2, ha, km2, m, km and count\",",
        "\"supported stats: mean, max, min, sum, stdev, mode and area \",",
        "\"if stat is area, provide cell value to extract\",",
        "\"supported types: raster, vector\",\"national or regional\""
      )
    )
  )
})
