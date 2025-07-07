
setup <- function() {

  toml <- "setup.toml"
  configs <- RcppTOML::parseTOML(toml)
  
  return(
    list(
      paths = configs$local,
      wtw = configs$wtw
    )
  )
}
