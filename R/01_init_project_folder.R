#' Initialize WTW project folder
#'
#' Creates an empty WTW project directory structure and dataprep.csv template
#' by calling [constechr::create_wtw_project_folder()] and
#' [constechr::create_dataprep_template()].
#'
#' @param project_dir Character string. Path to the WTW project directory.
#'
#' @return Invisibly returns the path to the dataprep.csv template.
#' Side effects: folder structure and dataprep.csv template is created on disk.
#'
#' @seealso [constechr::create_wtw_project_folder()],
#' [constechr::create_dataprep_template()]
#'
#' -----------------------------------------------------------------------------

init_project_folder <- function(project_dir) {

  # Build empty project directory
  constechr::create_wtw_project_folder(project_dir = project_dir)

  # Add dataprep.csv template to dataprep folder
  constechr::create_dataprep_template(project_dir = project_dir)

}
