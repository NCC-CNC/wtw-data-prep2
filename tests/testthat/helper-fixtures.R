# Test fixtures: a tiny NAT_DATA folder and AOIs, built at test time in
# tempdir(), with answers worked out by hand.
#
# Template (`_1km/idx.tif`): 10 x 10 cells of 1000 m in Canada_Albers_WGS_1984,
# extent x 600,000 to 610,000 and y 1,500,000 to 1,510,000, INT4S with NoData
# -9999, like NAT_DATA's. terra numbers cells row by row from the top left
# (cell = (row - 1) * 10 + col). Each cell holds a national id numbered from
# the bottom-left, id = (10 - row) * 10 + col, except cells 1 12 13 14 24 100,
# which are NA. 94 cells have data.
#
#            col 1   2   3   4   5  ...
#   row  1     NA  92  93  94  95
#   row  2     81  NA  NA  NA  85
#   row  3     71  72  73  NA  75
#   row  4     61  62  63  64  65
#   ...
#   row 10      1   2   3   4   5  ...  10 is NA (cell 100)
#
# AOI (`fixture_aoi_sf()`): one rectangle, x offsets 1300 to 3600 and y
# offsets 1200 to 3700 from the template's left and top edges (no edge on a
# cell boundary). It touches rows 2 to 4, cols 2 to 4: cells 12 13 14 22 23 24
# 32 33 34. Template NA cells drop 12 13 14 24, leaving 5 planning units:
#
#   cell  22  23  32  33  34
#   id    72  73  62  63  64
#
# Sorted by id (NCCID): 62 63 64 72 73 -> PUID 1 to 5. Row 2 has no planning
# units, so the trimmed pu_1km.tif covers rows 3 to 4, cols 2 to 4 (2 x 3,
# x 601,000 to 604,000, y 1,506,000 to 1,508,000), cell order 22 23 24 32 33 34
# with 24 NA.
#
# Layers, values in the 6 cells of pu_1km.tif (22 23 24 32 33 34) once
# extracted; elsewhere in the template they hold other values, which must not
# leak in:
#
#   E_NAT_Urban_fixture          INT1U  0     0     NA  0    0    1
#   I_NAT_Protected_fixture      INT1U  1     0     NA  0    1    0
#   T_NAT_HABITAT_Forest_fix..   FLT4S  0.5   10.25 NA  0    100  42.75
#   T_NAT_ECCC_CH_SPA            INT2U  5     12    NA  0    7    3   (11.6 rounded)
#   T_NAT_ECCC_CH_SPB            INT2U  4     0     NA  0    0    0
#   T_NAT_ECCC_CH_SPC            INT2U  2     2     NA  2    2    2
#   T_NAT_ECCC_CH_SPD            no values in the AOI: not written
#   W_NAT_Carbon_fixture_t       FLT4S  -1.5  2     NA  4.5  8    16
#   W_NAT_Climate_fixture        inactive: not written
#
# The source files' stored data types differ from the catalogue's (habitat
# FLT8S, include INT2U) so the catalogue's `datatype` is what is pinned.

# --- grid --------------------------------------------------------------------

# Canada_Albers_WGS_1984, the national template's CRS, as ESRI WKT
fixture_crs <- function() {
  paste0(
    'PROJCS["Canada_Albers_WGS_1984",',
    'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",',
    'SPHEROID["WGS_1984",6378137.0,298.257223563]],',
    'PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],',
    'PROJECTION["Albers"],',
    'PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],',
    'PARAMETER["Central_Meridian",-96.0],',
    'PARAMETER["Standard_Parallel_1",50.0],',
    'PARAMETER["Standard_Parallel_2",70.0],',
    'PARAMETER["Latitude_Of_Origin",40.0],UNIT["Meter",1.0]]'
  )
}

# Template extent, in metres
FIX_XMIN <- 600000
FIX_YMAX <- 1510000

# Template cells that are NA
fixture_na_cells <- function() c(1, 12, 13, 14, 24, 100)

# Planning-unit cells (template cell numbers), in pu_1km.tif cell order
fixture_pu_cells <- function() c(22, 23, 24, 32, 33, 34)

# An empty 10 x 10 raster on the template's grid
fixture_grid <- function() {
  terra::rast(
    nrows = 10, ncols = 10,
    xmin = FIX_XMIN, xmax = FIX_XMIN + 10000,
    ymin = FIX_YMAX - 10000, ymax = FIX_YMAX,
    crs = fixture_crs()
  )
}

# The template: national ids numbered from the bottom-left, NA in
# `fixture_na_cells()`
fixture_template <- function() {
  x <- fixture_grid()
  cells <- seq_len(terra::ncell(x))
  v <- (10 - terra::rowFromCell(x, cells)) * 10 + terra::colFromCell(x, cells)
  v[fixture_na_cells()] <- NA
  terra::values(x) <- v
  names(x) <- "idx"
  x
}

# A raster on the template's grid: `background` everywhere, `values` in
# `cells`
fixture_layer <- function(cells, values, background = 0, name = "layer") {
  x <- fixture_grid()
  v <- rep(background, terra::ncell(x))
  v[cells] <- values
  terra::values(x) <- v
  names(x) <- name
  x
}

# --- AOIs --------------------------------------------------------------------

# A rectangle from offsets (metres) from the template's left and top edges
fixture_rect <- function(x_from, x_to, y_from, y_to) {
  x <- FIX_XMIN + c(x_from, x_to)
  y <- FIX_YMAX - c(y_from, y_to)
  sf::st_polygon(list(matrix(
    c(x[1], y[1], x[2], y[1], x[2], y[2], x[1], y[2], x[1], y[1]),
    ncol = 2, byrow = TRUE
  )))
}

# The one-feature AOI (see the header), with a `region` attribute, in the
# template's CRS
fixture_aoi_sf <- function() {
  sf::st_sf(
    region = "Fixture",
    geometry = sf::st_sfc(
      fixture_rect(1300, 3600, 1200, 3700), crs = fixture_crs()
    )
  )
}

# A two-feature AOI, for the error case
fixture_aoi_two_sf <- function() {
  sf::st_sf(
    region = c("a", "b"),
    geometry = sf::st_sfc(
      fixture_rect(1300, 3600, 1200, 3700),
      fixture_rect(6200, 7800, 6200, 7800),
      crs = fixture_crs()
    )
  )
}

# Writes an AOI shapefile to `dir`, reprojected to Canada Atlas Lambert
# (EPSG:3978) so step 02's reprojection to the template's CRS is exercised
write_fixture_aoi <- function(dir, name = "fixture_aoi.shp", two = FALSE) {
  aoi <- if (two) fixture_aoi_two_sf() else fixture_aoi_sf()
  aoi <- sf::st_transform(aoi, 3978)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  sf::st_write(aoi, file.path(dir, name), quiet = TRUE, delete_layer = TRUE)
  invisible(file.path(dir, name))
}

# --- NAT_DATA ----------------------------------------------------------------

# Catalogue rows (WTW_NAT_PREP_METADATA.csv), one per branch the pipeline uses
fixture_catalogue <- function() {
  data.frame(
    product_id = 1:6,
    type = c("include", "theme", "theme", "weight", "exclude", "weight"),
    category = c(
      "protected", "species", "habitat", "carbon", "urban", "climate"
    ),
    legend_name = c(
      "Protected Areas", "ECCC SAR Critical Habitat", "Forest",
      "Carbon Storage", "Urban Areas", "Climate Refugia"
    ),
    theme_group_name = c("", "Critical Habitat", "Habitat", "", "", ""),
    short_name = c(
      "CPCAD", "ECCC_CH", "FOREST", "CARBON_S", "URBAN", "CLIMATE_R"
    ),
    ` file_name` = c(
      "Protected_fixture.tif", "eccc_ch.rds", "Forest_fixture_ha.tif",
      "Carbon_fixture_t.tif", "Urban_fixture.tif", "Climate_fixture.tif"
    ),
    path = c(
      "includes", "themes/species/eccc_ch", "themes/habitat",
      "weights/carbon", "excludes", "weights/climate"
    ),
    prefix = c("I_NAT_", "", "T_NAT_HABITAT_", "W_NAT_", "E_NAT_", "W_NAT_"),
    wtw_file_name = c(
      "I_NAT_Protected_fixture.tif", "", "T_NAT_HABITAT_Forest_fixture_ha.tif",
      "W_NAT_Carbon_fixture_t.tif", "E_NAT_Urban_fixture.tif",
      "W_NAT_Climate_fixture.tif"
    ),
    datatype = c("INT1U", "INT2U", "FLT4S", "FLT4S", "INT1U", "FLT4S"),
    legend_type = c(
      "manual", "continuous", "continuous", "continuous", "manual",
      "continuous"
    ),
    legend_color = c(
      "#00000000, #7fbc41", "Purples", "viridis", "YlOrBr",
      "#00000000, #7a7a7a", "magma"
    ),
    legend_label = c(
      "not included, included", "Non Habitat, Habitat", "", "",
      "not excluded, excluded", ""
    ),
    values = c("0, 1", "", "", "", "0, 1", ""),
    unit = c("km2", "ha", "ha", "tonnes", "km2", "index"),
    # A weight with a different provenance is tested separately (#22)
    provenance = rep("national", 6),
    visible = c(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE),
    hidden = rep(FALSE, 6),
    downloadable = rep(TRUE, 6),
    external = rep(TRUE, 6),
    active = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

# Writes a catalogue as NAT_DATA does: UTF-8 with a byte-order mark,
# fields quoted only where needed
write_catalogue <- function(x, path) {
  quote <- function(v) {
    v <- as.character(v)
    ifelse(grepl("[\",]", v), paste0("\"", gsub("\"", "\"\"", v), "\""), v)
  }
  lines <- c(
    paste(names(x), collapse = ","),
    do.call(paste, c(lapply(x, quote), sep = ","))
  )
  con <- file(path, "wb")
  on.exit(close(con))
  writeBin(as.raw(c(0xef, 0xbb, 0xbf)), con)
  writeBin(charToRaw(paste0(paste(lines, collapse = "\r\n"), "\r\n")), con)
  invisible(path)
}

# The ECCC_CH species rij matrix: one row per feature, one column per
# template cell with data (in cell order)
fixture_eccc_ch_rij <- function() {
  data_cells <- setdiff(1:100, fixture_na_cells())
  features <- list(
    T_NAT_ECCC_CH_SPA = list(
      cells = c(22, 23, 33, 34, 50, 99), x = c(5, 11.6, 7, 3, 9, 2)
    ),
    T_NAT_ECCC_CH_SPB = list(cells = c(22, 70), x = c(4, 4)),
    T_NAT_ECCC_CH_SPC = list(
      cells = c(22, 23, 32, 33, 34, 5), x = c(2, 2, 2, 2, 2, 2)
    ),
    # no values in the AOI
    T_NAT_ECCC_CH_SPD = list(cells = c(90, 91), x = c(6, 1))
  )
  i <- rep(seq_along(features), vapply(features, function(f) {
    length(f$cells)
  }, integer(1)))
  j <- match(unlist(lapply(features, `[[`, "cells")), data_cells)
  x <- unlist(lapply(features, `[[`, "x"))
  Matrix::sparseMatrix(
    i = i, j = j, x = unname(x),
    dims = c(length(features), length(data_cells)),
    dimnames = list(names(features), NULL)
  )
}

# Species metadata, ECCC_CH sheet (WTW_NAT_SPECIES_METADATA.xlsx)
fixture_species_eccc_ch <- function() {
  data.frame(
    Source = "ECCC_CH",
    File = paste0("T_NAT_ECCC_CH_", c("SPA", "SPB", "SPC", "SPD"), ".tif"),
    COSEWIC_ID = c(101, 102, 103, 104),
    Theme = "SAR Critical Habitat (ECCC)",
    Sci_Name = c("Carex fixtura", "Braya fixtura", "Lotus fixtura", "Nulla"),
    Common_Name = c(
      "Fixture Sedge", "Fixture's Braya", "Fixture Lotus", "Absent Species"
    ),
    Threat = "END",
    Total_Km2 = c(10, 20, 30, 40),
    Protected_Km2 = c(1, 2, 3, 4),
    Pct_Protected = c(10, 10, 10, 10),
    Goal = c(1, 0.5, 0.25, 1),
    stringsAsFactors = FALSE
  )
}

# Builds a NAT_DATA-like folder and returns its path. The species workbook
# needs openxlsx (readxl can't write); without it, it is left out.
make_natdata <- function(dir = new_temp_dir("natdata")) {
  dir.create(file.path(dir, "_1km"), recursive = TRUE, showWarnings = FALSE)
  terra::writeRaster(
    fixture_template(), file.path(dir, "_1km", "idx.tif"),
    datatype = "INT4S", NAflag = -9999, overwrite = TRUE
  )

  write_layer <- function(x, path, datatype) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    terra::writeRaster(x, path, datatype = datatype, overwrite = TRUE)
  }
  pu <- fixture_pu_cells()
  # include: stored INT2U, catalogue INT1U
  write_layer(
    fixture_layer(c(pu, 50, 77), c(1, 0, 1, 0, 1, 0, 1, 1)),
    file.path(dir, "includes", "Protected_fixture.tif"), "INT2U"
  )
  # habitat: stored FLT8S, catalogue FLT4S; cell 24 (template NA) holds 99
  write_layer(
    fixture_layer(pu, c(0.5, 10.25, 99, 0, 100, 42.75), background = 1),
    file.path(dir, "themes", "habitat", "Forest_fixture_ha.tif"), "FLT8S"
  )
  # weight
  write_layer(
    fixture_layer(pu, c(-1.5, 2, 50, 4.5, 8, 16), background = 3),
    file.path(dir, "weights", "carbon", "Carbon_fixture_t.tif"), "FLT4S"
  )
  # exclude
  write_layer(
    fixture_layer(c(pu, 12, 60), c(0, 0, 1, 0, 0, 1, 1, 1)),
    file.path(dir, "excludes", "Urban_fixture.tif"), "INT1U"
  )
  # inactive weight
  write_layer(
    fixture_layer(integer(0), numeric(0), background = 3),
    file.path(dir, "weights", "climate", "Climate_fixture.tif"), "FLT4S"
  )
  # species rij
  dir.create(
    file.path(dir, "themes", "species", "eccc_ch"),
    recursive = TRUE, showWarnings = FALSE
  )
  saveRDS(
    fixture_eccc_ch_rij(),
    file.path(dir, "themes", "species", "eccc_ch", "eccc_ch.rds")
  )

  write_catalogue(
    fixture_catalogue(), file.path(dir, "WTW_NAT_PREP_METADATA.csv")
  )
  if (requireNamespace("openxlsx", quietly = TRUE)) {
    openxlsx::write.xlsx(
      list(ECCC_CH = fixture_species_eccc_ch()),
      file.path(dir, "WTW_NAT_SPECIES_METADATA.xlsx")
    )
  }
  dir
}

# Runs steps 01-03 on a new project in tempdir() and returns its path
make_project <- function(natdata_dir, project_dir = new_temp_dir("project")) {
  source_pipeline(c(
    "01_init_project_folder.R", "02_aoi_to_1km_grid.R", "03_natdata.R"
  ))
  init_project_folder(project_dir = project_dir)
  write_fixture_aoi(file.path(project_dir, "aoi"))
  suppressMessages({
    aoi_to_grid(
      natdata_dir = natdata_dir,
      project_dir = project_dir,
      aoi_shp = "fixture_aoi.shp"
    )
    natdata(natdata_dir = natdata_dir, project_dir = project_dir)
  })
  project_dir
}

# --- expected answers --------------------------------------------------------

# Expected extracted layers: relative path under tifs/, data type, NoData and
# values in pu_1km.tif's 6 cells (22 23 24 32 33 34)
expected_tifs <- function() {
  list(
    "excludes/E_NAT_Urban_fixture.tif" = list(
      datatype = "INT1U", nodata = 255, values = c(0, 0, NA, 0, 0, 1)
    ),
    "includes/I_NAT_Protected_fixture.tif" = list(
      datatype = "INT1U", nodata = 255, values = c(1, 0, NA, 0, 1, 0)
    ),
    "themes/habitat/T_NAT_HABITAT_Forest_fixture_ha.tif" = list(
      datatype = "FLT4S", nodata = NaN,
      values = c(0.5, 10.25, NA, 0, 100, 42.75)
    ),
    "themes/species/eccc_ch/T_NAT_ECCC_CH_SPA.tif" = list(
      datatype = "INT2U", nodata = 65535, values = c(5, 12, NA, 0, 7, 3)
    ),
    "themes/species/eccc_ch/T_NAT_ECCC_CH_SPB.tif" = list(
      datatype = "INT2U", nodata = 65535, values = c(4, 0, NA, 0, 0, 0)
    ),
    "themes/species/eccc_ch/T_NAT_ECCC_CH_SPC.tif" = list(
      datatype = "INT2U", nodata = 65535, values = c(2, 2, NA, 2, 2, 2)
    ),
    "weights/carbon/W_NAT_Carbon_fixture_t.tif" = list(
      datatype = "FLT4S", nodata = NaN, values = c(-1.5, 2, NA, 4.5, 8, 16)
    )
  )
}

# Expected wtw-metadata.csv (step 04), all columns as character
expected_wtw_metadata <- function() {
  data.frame(
    Type = c(
      "exclude", "include", "theme", "theme", "theme", "theme", "weight"
    ),
    Theme = c(
      "", "", "Habitat", "Critical Habitat", "Critical Habitat",
      "Critical Habitat", ""
    ),
    File = c(
      "E_NAT_Urban_fixture.tif", "I_NAT_Protected_fixture.tif",
      "T_NAT_HABITAT_Forest_fixture_ha.tif", "T_NAT_ECCC_CH_SPA.tif",
      "T_NAT_ECCC_CH_SPB.tif", "T_NAT_ECCC_CH_SPC.tif",
      "W_NAT_Carbon_fixture_t.tif"
    ),
    Name = c(
      "Urban Areas", "Protected Areas", "Forest", "Fixture Sedge",
      "Fixture's Braya", "Fixture Lotus", "Carbon Storage"
    ),
    Legend = c(
      "manual", "manual", "continuous", "continuous", "manual", "manual",
      "continuous"
    ),
    Values = c("0, 1", "0, 1", "", "", "0,4", "2", ""),
    Color = c(
      "#00000000, #7a7a7a", "#00000000, #7fbc41", "viridis", "Purples",
      "#00000000, #756bb1", "#756bb1", "YlOrBr"
    ),
    Labels = c(
      "not excluded, excluded", "not included, included", "",
      "Non Habitat, Habitat", "Non Habitat, Habitat", "Habitat", ""
    ),
    Unit = c("km2", "km2", "ha", "ha", "ha", "ha", "tonnes"),
    Provenance = rep("national", 7),
    Visible = c("TRUE", "TRUE", "FALSE", "FALSE", "FALSE", "FALSE", "FALSE"),
    Hidden = rep("FALSE", 7),
    Downloadable = rep("TRUE", 7),
    Goal = c("", "", "0.2", "1", "0.5", "0.25", ""),
    stringsAsFactors = FALSE
  )
}

# --- readers -----------------------------------------------------------------

# A GeoTIFF's NoData value, as GDAL reports it
file_nodata <- function(path) {
  line <- grep("NoData Value=", terra::describe(path), value = TRUE)[1]
  as.numeric(sub(".*NoData Value=", "", line))
}

# A raster file's first-layer values, as a plain numeric vector (NaN as NA)
file_values <- function(path) {
  v <- as.numeric(terra::values(terra::rast(path)[[1]], mat = FALSE))
  v[is.nan(v)] <- NA
  v
}

# Reads a CSV with every column as character and empty fields kept as ""
read_csv_chr <- function(path) {
  utils::read.csv(
    path, colClasses = "character", na.strings = character(0),
    check.names = FALSE
  )
}
