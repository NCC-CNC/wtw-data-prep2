#' Setup WTW Project
#' 
#' Installs any missing R packages required by the WTW project, reads in
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
    "gdalUtilities",
    "dplyr",
    "glue",
    "prioritizr",
    "RcppTOML",
    "RColorBrewer",
    "readxl",
    "R6",
    "sf",
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
