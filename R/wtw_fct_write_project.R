
#' Write project
#'
#' Save a project to disk.
#'
#' @param x `list` of [Theme], [Weight], [Include], and [Exclude] objects.
#'
#' @param dataset [Dataset] object.
#'
#' @param name `character` name for the scenario.
#'
#' @param path `character` file path to save the configuration file.
#'
#' @param spatial_path `character` file path for the spatial data.
#'
#' @param attribute_path `character` file path for the attribute data.
#'
#' @param boundary_path `character` file path for the attribute data.
#'
#' @param mode `character` mode for running the application.
#'   Defaults to `"advanced"`.
#'
#' @param author_name `character` name of the project author.
#'   Defaults to `NULL` such that no author name is encoded in the
#'   project configuration file. This means that the application
#'   will report default contact details.
#'
#' @param author_email `character` email address of the project author.
#'   Defaults to `NULL` such that no email address is encoded in the
#'   project configuration file. This means that the application
#'   will report default contact details.
#'
#' @param mode `character` mode for running the application.
#'   Defaults to `"advanced"`.
#'
#' @param user_groups `character` vector of user groups than can
#'   access the dataset.
#'   Defaults to `"public"`.
#'
#' @return Invisible `TRUE` indicating success.
#'
#' @examples
#'  # find data file paths
#'  f1 <- system.file(
#'    "extdata", "projects", "sim_raster", "sim_raster_spatial.tif",
#'    package = "wheretowork"
#'  )
#'  f2 <- system.file(
#'    "extdata", "projects", "sim_raster", "sim_raster_attribute.csv.gz",
#'    package = "wheretowork"
#'  )
#'  f3 <- system.file(
#'    "extdata", "projects", "sim_raster", "sim_raster_boundary.csv.gz",
#'    package = "wheretowork"
#'  )
#'
#'  # create new dataset
#'  d <- new_dataset(f1, f2, f3)
#'
#'  # simulate themes and weights
#'  th <- simulate_themes(d, 1, 1, 2)
#'  w <- simulate_weights(d, 1)
#'
#'  # combine themes and weights into a list
#'  l <- append(th, w)
#'
#'  # save project
#'  write_project(
#'    x = l,
#'    name = "example",
#'    dataset = d,
#'    path = tempfile(),
#'    spatial_path = tempfile(fileext = ".tif"),
#'    attribute_path = tempfile(fileext = ".csv.gz"),
#'    boundary_path = tempfile(fileext = ".csv.gz")
#'  )
#' @export
write_project <- function(
    themes_params = NULL,
    weights_params = NULL,
    includes_params = NULL,
    excludes_params = NULL, 
    dataset, 
    path, 
    name,
    spatial_path, 
    attribute_path, 
    boundary_path,
    mode = "advanced",
    user_groups = "public",
    author_name = NULL, 
    author_email = NULL
    ) {
  
  # create full settings list
  ## add project name
  params <- list()
  ## add project name
  params$name <- name
  ## add contact details
  if (!is.null(author_name)) {
    params$author_name <- author_name
    params$author_email <- author_email
  }
  ## add data prep date
  params$data_prep_date <- as.character(Sys.Date())
  ## add wheretowork version 
  params$wheretowork_version <- "1.2.5"
  ## add prioritizr version
  params$prioritizr_version <- "8.0.6"  
  ## specify application mode
  params$mode <- mode
  ## add user groups
  params$user_groups <- user_groups
  ## add data
  params$spatial_path <- basename(spatial_path)
  params$attribute_path <- basename(attribute_path)
  params$boundary_path <- basename(boundary_path)
  params$themes <- themes_params
  params$weights <- weights_params
  params$includes <- includes_params
  params$excludes <- excludes_params
  
  # coerce characters to ASCII
  params <- enc2ascii(params)
  
  # save configuration file to disk
  yaml::write_yaml(params, path)
  
  # save dataset to disk
  dataset$write(spatial_path, attribute_path, boundary_path)
  
  # return success
  invisible(TRUE)
}
