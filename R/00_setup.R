
setup <- function() {
  
  required_pkgs <- c(
    "assertthat",
    "data.table",
    "dplyr",
    "glue",
    "prioritizr",
    "RcppTOML",
    "readxl",
    "R6",
    "sf",
    "stringr",
    "terra",
    "tibble",
    "uuid",
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
