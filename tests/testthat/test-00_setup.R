# 00 Setup: setup() reads setup.toml from the working directory and installs
# missing packages. install.packages() is replaced in setup()'s environment so
# no test can install anything; tests that reach remotes::install_github()
# mock it, and the others skip unless constechr >= 0.2.0 is installed.

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

test_that("setup() checks every required package, without loading constechr", {
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

  # constechr's version is read from its DESCRIPTION; requireNamespace() would
  # load it, and reinstalling a loaded package corrupts it for the session
  expect_setequal(checked, SETUP_PKGS)
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

# --- constechr installs ------------------------------------------------------

# Sources 00_setup.R with every required package present, constechr at
# `version` (NULL: not installed) and `loaded` or not, and records the
# unloadNamespace() and remotes::install_github() calls in env$events
constechr_env <- function(version, loaded, frame = parent.frame()) {
  skip_if_not_installed("remotes")
  env <- setup_env()
  env$events <- list()
  env$requireNamespace <- function(package, ..., quietly = FALSE) TRUE
  env$loadedNamespaces <- function() {
    c(if (loaded) "constechr", "base", "utils")
  }
  env$unloadNamespace <- function(ns) {
    env$events[[length(env$events) + 1]] <- list("unload", ns)
    invisible(NULL)
  }
  local_mocked_bindings(
    packageVersion = function(pkg, ...) {
      if (pkg != "constechr") stop("unexpected package: ", pkg)
      if (is.null(version)) stop("there is no package called 'constechr'")
      package_version(version)
    },
    .package = "utils",
    .env = frame
  )
  local_mocked_bindings(
    install_github = function(...) {
      env$events[[length(env$events) + 1]] <- list("install_github", list(...))
      invisible(TRUE)
    },
    .package = "remotes",
    .env = frame
  )
  env
}

test_that("setup() unloads an outdated constechr before installing it", {
  env <- constechr_env(version = "0.1.0.9009", loaded = TRUE)
  dir <- new_temp_dir("setup")
  write_setup_toml(dir)

  expect_message(with_dir(dir, env$setup()), "Installing constechr...")

  expect_equal(
    env$events,
    list(
      list("unload", "constechr"),
      list("install_github", list("NCC-CNC/constechr", upgrade = "never"))
    )
  )
  expect_length(env$installs, 0)
})

test_that("setup() installs a missing constechr without unloading it", {
  env <- constechr_env(version = NULL, loaded = FALSE)
  dir <- new_temp_dir("setup")
  write_setup_toml(dir)

  expect_message(with_dir(dir, env$setup()), "Installing constechr...")

  expect_equal(
    env$events,
    list(list("install_github", list("NCC-CNC/constechr", upgrade = "never")))
  )
})

test_that("setup() leaves an up-to-date constechr alone", {
  env <- constechr_env(version = "0.2.0", loaded = TRUE)
  dir <- new_temp_dir("setup")
  write_setup_toml(dir)

  with_dir(dir, env$setup())

  expect_length(env$events, 0)
  expect_length(env$installs, 0)
})
