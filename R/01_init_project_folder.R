#' Initialize WTW project folder
#'
#' Creates an empty WTW project directory structure by calling
#' [create_project_folder()].
#'
#' @param project_dir Character string. Path to the WTW project directory.
#'
#' @return Invisibly returns the path to the created project directory.
#' Side effects: folder structure and dataprep.csv template is created on disk.
#'
#' @seealso [create_project_folder()]
#' 
#' -----------------------------------------------------------------------------

# Source in function
source("R/fct_create_project_folder.R")
init_project_folder <- function(project_dir) {
  
  # Build empty project directory
  create_project_folder(project_dir = project_dir)
  
}
