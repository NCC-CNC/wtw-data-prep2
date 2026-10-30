#' Setup WTW Project
#' 
#' Installs any missing R packages required by the WTW project, including
#' constechr from GitHub (https://github.com/NCC-CNC/constechr), reads in
#' `setup.toml`, and stores user-specific paths and configuration settings
#' in memory.
#'
#' @return A list with two elements.
#' "paths" capture directories specified in the setup.toml under "local".
#' "wtw" captures WTW-specific settings specified in the setup.toml under "wtw".
#' 
#' -----------------------------------------------------------------------------

setup <- function() {
  
  required_pkgs <- c(
    "assertthat",
    "data.table",
    "dplyr",
    "glue",
    "prioritizr",
    "RcppTOML",
    "RColorBrewer",
    "readr",
    "readxl",
    "R6",
    "sf",
    "stringi",
    "stringr",
    "terra",
    "tibble",
    "uuid",
    "viridisLite", 
    "yaml"
  )
  
  # Install missing packages
  for (pkg in required_pkgs) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message(sprintf("Installing %s...", pkg))
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
  }

  # Install constechr from GitHub if missing or older than the pipeline needs
  if (!requireNamespace("constechr", quietly = TRUE) ||
      utils::packageVersion("constechr") < "0.2.0") {
    if (!requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes", repos = "https://cloud.r-project.org")
    }
    message("Installing constechr...")
    remotes::install_github("NCC-CNC/constechr", upgrade = "never")
  }

  # Read-in toml and return configs
  toml <- "setup.toml"
  configs <- RcppTOML::parseTOML(toml)
  
  return(
    list(
      paths = configs$local,
      wtw = configs$wtw
    )
  )
}
