source_pipeline("05_wtw.R")

# Step 05 reads the project's tifs/ and wtw-metadata.csv. The metadata is
# written from expected_wtw_metadata() (what step 04 writes, pinned in
# test-04_metadata.R), so these tests don't need openxlsx.
#
# Note: 05 writes to <project_dir>/WTW while 01 creates <project_dir>/wtw;
# that is the same folder only on a case-insensitive file system (Windows).

NATDATA_05 <- make_natdata()
PROJECT_05 <- make_project(NATDATA_05)
utils::write.csv(
  expected_wtw_metadata(),
  file.path(PROJECT_05, "wtw", "metadata", "wtw-metadata.csv"),
  row.names = FALSE
)

WTW_FILES <- c(
  "fixture-configs.yaml", "fixture-spatial.tif", "fixture-attribute.csv.gz",
  "fixture-boundary.csv.gz"
)

run_wtw <- function(project_dir) {
  build_wtw_project(
    project_dir = project_dir,
    punits = "aoi/pu_1km.tif",
    wtw_metadata = "wtw/metadata/wtw-metadata.csv",
    author = "Ada Lovelace",
    email = "ada@example.org",
    groups = "private",
    project_name = "Fixture Project",
    file_name = "fixture"
  )
  invisible(project_dir)
}

wtw_path <- function(project_dir, file) file.path(project_dir, "WTW", file)

# Reads, edits and rewrites a project's wtw-metadata.csv
edit_metadata <- function(project_dir, fun) {
  path <- file.path(project_dir, "wtw", "metadata", "wtw-metadata.csv")
  utils::write.csv(fun(read_csv_chr(path)), path, row.names = FALSE)
}

# Expected colour palettes
VIRIDIS_5 <- c("#440154FF", "#3B528BFF", "#21908CFF", "#5DC863FF", "#FDE725FF")
PURPLES_9 <- c(
  "#FCFBFD", "#EFEDF5", "#DADAEB", "#BCBDDC", "#9E9AC8", "#807DBA",
  "#6A51A3", "#54278F", "#3F007D"
)
YLORBR_9 <- c(
  "#FFFFE5", "#FFF7BC", "#FEE391", "#FEC44F", "#FE9929", "#EC7014",
  "#CC4C02", "#993404", "#662506"
)

# A theme feature as build_wtw_project() writes it
theme_feature <- function(name, index, legend, goal) {
  list(
    name = name,
    variable = list(
      index = index, units = "ha", legend = legend, provenance = "national"
    ),
    status = TRUE,
    visible = FALSE,
    hidden = FALSE,
    downloadable = TRUE,
    goal = goal,
    limit_goal = 0
  )
}

PROJECT_05_RUN <- copy_dir(PROJECT_05, "project")
run_wtw(PROJECT_05_RUN)
CONFIG_05 <- yaml::read_yaml(wtw_path(PROJECT_05_RUN, "fixture-configs.yaml"))

# --- outputs -----------------------------------------------------------------

test_that("build_wtw_project() writes the 4 WTW files", {
  expect_true(all(file.exists(wtw_path(PROJECT_05_RUN, WTW_FILES))))
})

test_that("the YAML has the project settings", {
  expect_identical(
    names(CONFIG_05),
    c(
      "name", "author_name", "author_email", "data_prep_date",
      "wheretowork_version", "prioritizr_version", "mode", "user_groups",
      "spatial_path", "attribute_path", "boundary_path", "themes", "weights",
      "includes", "excludes"
    )
  )
  expect_identical(CONFIG_05$name, "Fixture Project")
  expect_identical(CONFIG_05$author_name, "Ada Lovelace")
  expect_identical(CONFIG_05$author_email, "ada@example.org")
  expect_match(CONFIG_05$data_prep_date, "^\\d{4}-\\d{2}-\\d{2}$")
  expect_identical(CONFIG_05$wheretowork_version, "1.2.7")
  expect_identical(CONFIG_05$prioritizr_version, "8.0.6")
  expect_identical(CONFIG_05$mode, "advanced")
  expect_identical(CONFIG_05$user_groups, "private")
  expect_identical(CONFIG_05$spatial_path, "fixture-spatial.tif")
  expect_identical(CONFIG_05$attribute_path, "fixture-attribute.csv.gz")
  expect_identical(CONFIG_05$boundary_path, "fixture-boundary.csv.gz")
})

test_that("the YAML themes are grouped by Theme in metadata order", {
  expect_identical(
    CONFIG_05$themes,
    list(
      list(
        name = "Habitat",
        feature = list(
          theme_feature(
            "Forest", "T_NAT_HABITAT_Forest_fixture_ha",
            list(type = "continuous", colors = VIRIDIS_5), 0.2
          )
        )
      ),
      list(
        name = "Critical Habitat",
        feature = list(
          theme_feature(
            "Fixture Sedge", "T_NAT_ECCC_CH_SPA",
            list(type = "continuous", colors = PURPLES_9), 1
          ),
          theme_feature(
            "Fixture's Braya", "T_NAT_ECCC_CH_SPB",
            list(
              type = "manual",
              colors = c("#00000000", "#756bb1"),
              labels = c("Non Habitat", "Habitat")
            ),
            0.5
          ),
          theme_feature(
            "Fixture Lotus", "T_NAT_ECCC_CH_SPC",
            list(type = "manual", colors = "#756bb1", labels = "Habitat"),
            0.25
          )
        )
      )
    )
  )
})

test_that("the YAML has the expected weights, includes and excludes", {
  expect_identical(
    CONFIG_05$weights,
    list(list(
      name = "Carbon Storage",
      variable = list(
        index = "W_NAT_Carbon_fixture_t",
        units = "tonnes",
        legend = list(type = "continuous", colors = YLORBR_9),
        provenance = "national"
      ),
      status = TRUE,
      visible = FALSE,
      hidden = FALSE,
      downloadable = TRUE,
      factor = 0
    ))
  )
  expect_identical(
    CONFIG_05$includes,
    list(list(
      name = "Protected Areas",
      variable = list(
        index = "I_NAT_Protected_fixture",
        units = "km2",
        legend = list(
          type = "manual",
          colors = c("#00000000", "#7fbc41"),
          labels = c("not included", "included")
        ),
        provenance = "national"
      ),
      mandatory = FALSE,
      status = TRUE,
      visible = TRUE,
      hidden = FALSE,
      downloadable = TRUE,
      overlap = NA_character_
    ))
  )
  expect_identical(
    CONFIG_05$excludes,
    list(list(
      name = "Urban Areas",
      variable = list(
        index = "E_NAT_Urban_fixture",
        units = "km2",
        legend = list(
          type = "manual",
          colors = c("#00000000", "#7a7a7a"),
          labels = c("not excluded", "excluded")
        ),
        provenance = "national"
      ),
      mandatory = FALSE,
      status = TRUE,
      visible = TRUE,
      hidden = FALSE,
      downloadable = TRUE,
      overlap = NA_character_
    ))
  )
})

test_that("spatial.tif is the first theme layer on the planning units", {
  path <- wtw_path(PROJECT_05_RUN, "fixture-spatial.tif")
  r <- terra::rast(path)

  expect_identical(names(r), "T_NAT_HABITAT_Forest_fixture_ha")
  expect_true(terra::compareGeom(
    r, terra::rast(file.path(PROJECT_05_RUN, "aoi", "pu_1km.tif")),
    stopOnError = FALSE
  ))
  expect_identical(file_nodata(path), -9999)
  expect_identical(file_values(path), c(0.5, 10.25, NA, 0, 100, 42.75))
})

test_that("attribute.csv.gz has every layer, weights clamped at 0", {
  x <- as.data.frame(data.table::fread(
    wtw_path(PROJECT_05_RUN, "fixture-attribute.csv.gz")
  ))

  # planning units 22 23 32 33 34 are cells 1 2 4 5 6 of pu_1km.tif
  expect_equal(
    x,
    data.frame(
      T_NAT_HABITAT_Forest_fixture_ha = c(0.5, 10.25, 0, 100, 42.75),
      T_NAT_ECCC_CH_SPA = c(5, 12, 0, 7, 3),
      T_NAT_ECCC_CH_SPB = c(4, 0, 0, 0, 0),
      T_NAT_ECCC_CH_SPC = c(2, 2, 2, 2, 2),
      W_NAT_Carbon_fixture_t = c(0, 2, 4.5, 8, 16),
      I_NAT_Protected_fixture = c(1, 0, 0, 1, 0),
      E_NAT_Urban_fixture = c(0, 0, 0, 0, 1),
      `_index` = c(1, 2, 4, 5, 6),
      check.names = FALSE
    ),
    ignore_attr = TRUE
  )
})

test_that("boundary.csv.gz has cell perimeters and shared edges", {
  x <- as.data.frame(data.table::fread(
    wtw_path(PROJECT_05_RUN, "fixture-boundary.csv.gz")
  ))
  x <- x[order(x$i, x$j), ]

  # rows 0-4 are cells 22 23 32 33 34; shared 1000 m edges: 22-23, 22-32,
  # 23-33, 32-33, 33-34
  expect_equal(
    x,
    data.frame(
      i = c(0, 0, 0, 1, 1, 2, 2, 3, 3, 4),
      j = c(0, 1, 2, 1, 3, 2, 3, 3, 4, 4),
      x = c(4000, 1000, 1000, 4000, 1000, 4000, 1000, 4000, 1000, 4000)
    ),
    ignore_attr = TRUE
  )
})

# --- all-zero layers ---------------------------------------------------------

test_that("an all-zero layer is dropped with a warning", {
  project_dir <- copy_dir(PROJECT_05, "project")
  forest <- file.path(
    project_dir, "tifs", "themes", "habitat",
    "T_NAT_HABITAT_Forest_fixture_ha.tif"
  )
  zero <- terra::rast(forest) * 0
  names(zero) <- "Zero"
  terra::writeRaster(
    zero, file.path(dirname(forest), "T_NAT_HABITAT_Zero.tif"),
    datatype = "FLT4S"
  )
  edit_metadata(project_dir, function(m) {
    row <- m[m$File == "T_NAT_HABITAT_Forest_fixture_ha.tif", ]
    row$File <- "T_NAT_HABITAT_Zero.tif"
    row$Name <- "Zero"
    rbind(m, row)
  })

  expect_warning(
    run_wtw(project_dir),
    paste0(
      "Dropping 1 layer(s) with all zero/NA values in the AOI:\n",
      "  - T_NAT_HABITAT_Zero.tif"
    ),
    fixed = TRUE
  )

  expect_true(all(file.exists(wtw_path(project_dir, WTW_FILES))))
  config <- yaml::read_yaml(wtw_path(project_dir, "fixture-configs.yaml"))
  expect_identical(config$themes, CONFIG_05$themes)
  attribute <- data.table::fread(
    wtw_path(project_dir, "fixture-attribute.csv.gz")
  )
  expect_false("T_NAT_HABITAT_Zero" %in% names(attribute))
})

# --- validation --------------------------------------------------------------

# Runs build_wtw_project() expecting an error, and checks nothing was written
expect_wtw_error <- function(project_dir, regexp) {
  expect_error(run_wtw(project_dir), regexp, fixed = TRUE)
  expect_false(any(file.exists(wtw_path(project_dir, WTW_FILES))))
}

test_that("check 1: a metadata file missing from tifs/ stops", {
  project_dir <- copy_dir(PROJECT_05, "project")
  edit_metadata(project_dir, function(m) {
    row <- m[1, ]
    row$File <- "missing.tif"
    row$Name <- "Missing"
    rbind(m, row)
  })

  expect_wtw_error(
    project_dir,
    paste0(
      "The following files are listed in metadata but not found in tifs/:\n",
      "  - Row 9: missing.tif (Name: 'Missing', Type: 'exclude')"
    )
  )
})

test_that("check 2: a tif with no metadata row stops", {
  project_dir <- copy_dir(PROJECT_05, "project")
  file.copy(
    file.path(project_dir, "tifs", "excludes", "E_NAT_Urban_fixture.tif"),
    file.path(project_dir, "tifs", "excludes", "E_NAT_Extra.tif")
  )

  expect_wtw_error(
    project_dir,
    "The following tif files have no entry in the metadata:\n  - E_NAT_Extra.tif"
  )
})

test_that("check 3: an invalid Type stops", {
  project_dir <- copy_dir(PROJECT_05, "project")
  edit_metadata(project_dir, function(m) {
    m$Type[m$File == "W_NAT_Carbon_fixture_t.tif"] <- "feature"
    m
  })

  expect_wtw_error(
    project_dir,
    paste0(
      "The following metadata rows have invalid Type values (must be one ",
      "of: theme, include, weight, exclude):\n",
      "  - W_NAT_Carbon_fixture_t.tif (Type = 'feature')"
    )
  )
})

test_that("check 4: a manual legend that doesn't match the raster stops", {
  project_dir <- copy_dir(PROJECT_05, "project")
  edit_metadata(project_dir, function(m) {
    m$Values[m$File == "T_NAT_ECCC_CH_SPB.tif"] <- "0, 1"
    m
  })

  expect_wtw_error(
    project_dir,
    paste0(
      "Mismatch between raster values and metadata for manual legends:\n",
      "  - Row 6: T_NAT_ECCC_CH_SPB.tif (Name: 'Fixture's Braya')\n",
      "    raster values are {0, 4} but wtw-metadata.csv Values has {0, 1}"
    )
  )
})

# --- known bugs --------------------------------------------------------------

test_that("weights get their own provenance", {
  skip("Known bug #22: weights get theme provenance")
  project_dir <- copy_dir(PROJECT_05, "project")
  edit_metadata(project_dir, function(m) {
    m$Provenance[m$Type == "weight"] <- "regional"
    m
  })

  run_wtw(project_dir)

  config <- yaml::read_yaml(wtw_path(project_dir, "fixture-configs.yaml"))
  expect_identical(config$weights[[1]]$variable$provenance, "regional")
})
