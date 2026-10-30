# 00 Setup: setup() reads setup.toml from the working directory and installs
# missing packages. install.packages() is replaced in setup()'s environment so
# no test can install anything; remotes::install_github() can't be replaced
# that way, so tests skip unless constechr >= 0.2.0 is installed.

SETUP_PKGS <- c(
  "assertthat", "data.table", "dplyr", "glue", "prioritizr", "RcppTOML",
  "RColorBrewer", "readr", "readxl", "R6", "sf", "stringi", "stringr",
  "terra", "tibble", "uuid", "viridisLite", "yaml"
)

# Sources 00_setup.R into a new env whose install.packages() only records
# its calls (in env$installs)
setup_env <- function() {
  env <- new.env(parent = globalenv())
  source_pipeline("00_setup.R", env = env)
  env$installs <- list()
  env$install.packages <- function(...) {
    env$installs[[length(env$installs) + 1]] <- list(...)
    invisible(NULL)
  }
  env
}

skip_unless_setup_complete <- function() {
  for (pkg in SETUP_PKGS) {
    skip_if_not_installed(pkg)
  }
  skip_if_not_installed("constechr", minimum_version = "0.2.0")
}

write_setup_toml <- function(dir) {
  writeLines(
    c(
      "[local]",
      "project_dir = \"C:\\\\projects\\\\wtw\\\\fixture\"",
      "natdata_dir = \"C:\\\\NAT_DATA\\\\NAT_DATA_20261009\"",
      "aoi_shp = \"fixture_aoi.shp\"",
      "punits = \"aoi\\\\pu_1km.tif\"",
      "wtw_metadata = \"wtw\\\\metadata\\\\wtw-metadata.csv\"",
      "",
      "[wtw]",
      "project_name = \"Fixture Project\"",
      "file_name = \"fixture\"",
      "author = \"Ada Lovelace\"",
      "email = \"ada@example.org\"",
      "groups = \"private\""
    ),
    file.path(dir, "setup.toml")
  )
}

# --- setup.toml --------------------------------------------------------------

test_that("setup() returns the [local] and [wtw] tables of setup.toml", {
  skip_unless_setup_complete()
  env <- setup_env()
  dir <- new_temp_dir("setup")
  write_setup_toml(dir)

  configs <- with_dir(dir, expect_silent(env$setup()))

  expect_named(configs, c("paths", "wtw"))
  # RcppTOML::parseTOML() defaults to escape = TRUE, so each TOML "\\" comes
  # back as two backslashes, not one (Windows accepts the doubled separator)
  expect_mapequal(
    configs$paths,
    list(
      project_dir = "C:\\\\projects\\\\wtw\\\\fixture",
      natdata_dir = "C:\\\\NAT_DATA\\\\NAT_DATA_20261009",
      aoi_shp = "fixture_aoi.shp",
      punits = "aoi\\\\pu_1km.tif",
      wtw_metadata = "wtw\\\\metadata\\\\wtw-metadata.csv"
    )
  )
  expect_mapequal(
    configs$wtw,
    list(
      project_name = "Fixture Project",
      file_name = "fixture",
      author = "Ada Lovelace",
      email = "ada@example.org",
      groups = "private"
    )
  )
  expect_length(env$installs, 0)
})

test_that("setup() errors without a setup.toml in the working directory", {
  skip_unless_setup_complete()
  env <- setup_env()
  dir <- new_temp_dir("setup")

  expect_error(with_dir(dir, env$setup()))
})

# --- package installs --------------------------------------------------------

test_that("setup() checks every required package and constechr", {
  skip_unless_setup_complete()
  env <- setup_env()
  checked <- character(0)
  env$requireNamespace <- function(package, ..., quietly = FALSE) {
    checked <<- c(checked, package)
    TRUE
  }
  dir <- new_temp_dir("setup")
  write_setup_toml(dir)

  with_dir(dir, env$setup())

  expect_setequal(checked, c(SETUP_PKGS, "constechr"))
  expect_length(env$installs, 0)
})

test_that("setup() installs only the missing package, from CRAN", {
  skip_unless_setup_complete()
  env <- setup_env()
  env$requireNamespace <- function(package, ..., quietly = FALSE) {
    package != "yaml"
  }
  dir <- new_temp_dir("setup")
  write_setup_toml(dir)

  expect_message(with_dir(dir, env$setup()), "Installing yaml...", fixed = TRUE)
  expect_equal(
    env$installs,
    list(list("yaml", repos = "https://cloud.r-project.org"))
  )
})
