
source("R/wtw_class_Dataset.R")
source("R/wtw_fct_enc2ascii.R")
source("R/wtw_fct_color_palette.R")
source("R/wtw_fct_write_project.R")
build_wtw_project <- function(project_dir, author, email, groups, project_name) {
  
  meta_path <- file.path(project_dir, "wtw/metadata/wtw-metadata.csv") 
  pu_path <- file.path(project_dir,"aoi/pu_1km.tif")
  tifs_path <- file.path(project_dir, "tifs")
  tif_files_full_path <- list.files(tifs_path, pattern = "\\.tif$", recursive = TRUE, full.names = TRUE)
  tif_files <- basename(tif_files_full_path)
  
  # 3.0 Import meta data and PUs -------------------------------------------------
  
  ## Import formatted csv (metadata) as tibble 
  metadata <- tibble::as_tibble(
    utils::read.table(
      meta_path, stringsAsFactors = FALSE, sep = ",", header = TRUE,
      comment.char = "", quote="\""
    )
  )
  
  ## Validate metadata
  assertthat::assert_that(
    all(metadata$Type %in% c("theme", "include", "weight", "exclude")),
    all(tif_files %in% metadata$File)
  )
  
  ## Import study area (planning units) raster
  pu <- terra::rast(pu_path)
  
  
  # 3.1 Import rasters -----------------------------------------------------------
  
  ## Import theme, weight, include and exclude rasters as a list of SpatRasters 
  ## objects. If raster variable does not compare to planning unit, re-project raster 
  ## variable so it aligns to the study area.
  raster_data <- lapply(tif_files_full_path, function(x) {
    raster_x <- terra::rast(x)
    names(raster_x) <- tools::file_path_sans_ext(basename(x)) # file name
    if (terra::compareGeom(pu, raster_x, stopOnError=FALSE)) {
      raster_x
    } else {
      print(paste0(names(raster_x), ": can not stack"))
      print(paste0("... aligning to ", names(pu)))
      terra::project(raster_x, y = pu, method = "near")
    }
  }) 
  
  ## Convert list to a combined SpatRaster
  raster_data <- do.call(c, raster_data)
  
  # 4.0 Pre-processing -----------------------------------------------------------
  
  ## Prepare theme inputs ----
  theme_data <- raster_data[[which(metadata$Type == "theme")]]
  names(theme_data) <- gsub(".", "_", names(theme_data), fixed = TRUE)
  theme_names <- metadata$Name[metadata$Type == "theme"]
  theme_groups <- metadata$Theme[metadata$Type == "theme"]
  theme_colors <- metadata$Color[metadata$Type == "theme"]
  theme_units <- metadata$Unit[metadata$Type == "theme"]
  theme_visible <- metadata$Visible[metadata$Type == "theme"]
  theme_provenance <- metadata$Provenance[metadata$Type == "theme"]
  theme_hidden <- metadata$Hidden[metadata$Type == "theme"]
  theme_legend <- metadata$Legend[metadata$Type == "theme"]
  theme_labels <- metadata$Labels[metadata$Type == "theme"]
  theme_values <- metadata$Values[metadata$Type == "theme"]
  theme_goals <- metadata$Goal[metadata$Type == "theme"]
  theme_downloadble <- metadata$Downloadable[metadata$Type == "theme"]
  
  ## Prepare weight inputs (if there are any) ----
  if ("weight" %in% unique(metadata$Type)) {
    weight_data <- raster_data[[which(metadata$Type == "weight")]]
    weight_data <- terra::clamp(weight_data, lower = 0)
    weight_names <- metadata$Name[metadata$Type == "weight"]
    weight_colors <- metadata$Color[metadata$Type == "weight"]
    weight_units <- metadata$Unit[metadata$Type == "weight"]
    weight_visible <- metadata$Visible[metadata$Type == "weight"]
    weight_hidden <- metadata$Hidden[metadata$Type == "weight"]
    weight_provenance <- metadata$Provenance[metadata$Type == "weight"]
    weight_legend <- metadata$Legend[metadata$Type == "weight"]
    weight_labels <- metadata$Labels[metadata$Type == "weight"]
    weight_values <- metadata$Values[metadata$Type == "weight"]
    weight_downloadble <- metadata$Downloadable[metadata$Type == "weight"]
  } else {
    weight_data <- NULL
    weights_params <- NULL # no weights in project
  }
  
  ## Prepare include inputs (if there are any) ----
  if ("include" %in% unique(metadata$Type)) {
    include_data <- raster_data[[which(metadata$Type == "include")]]
    include_data <- terra::classify(include_data, matrix(c(-Inf,0.5,0, 0.5,Inf,1), ncol = 3, byrow = TRUE))
    include_names <- metadata$Name[metadata$Type == "include"]
    include_colors <- metadata$Color[metadata$Type == "include"]
    include_units <- metadata$Unit[metadata$Type == "include"]
    include_visible <- metadata$Visible[metadata$Type == "include"]
    include_provenance <- metadata$Provenance[metadata$Type == "include"]
    include_legend <- metadata$Legend[metadata$Type == "include"]
    include_labels <- metadata$Labels[metadata$Type == "include"]
    include_hidden <- metadata$Hidden[metadata$Type == "include"]
    include_downloadble <- metadata$Downloadable[metadata$Type == "include"]
  } else {
    include_data <- NULL
    includes_params <- NULL # no includes in project
  }
  
  ## Prepare exclude inputs (if there are any) ----
  if ("exclude" %in% unique(metadata$Type)) {
    exclude_data <- raster_data[[which(metadata$Type == "exclude")]]
    exclude_data <- terra::classify(exclude_data, matrix(c(-Inf,0.5,0, 0.5,Inf,1), ncol = 3, byrow = TRUE))
    exclude_names <- metadata$Name[metadata$Type == "exclude"]
    exclude_colors <- metadata$Color[metadata$Type == "exclude"]
    exclude_units <- metadata$Unit[metadata$Type == "exclude"]
    exclude_visible <- metadata$Visible[metadata$Type == "exclude"]
    exclude_provenance <- metadata$Provenance[metadata$Type == "exclude"]
    exclude_legend <- metadata$Legend[metadata$Type == "exclude"]
    exclude_labels <- metadata$Labels[metadata$Type == "exclude"]
    exclude_hidden <- metadata$Hidden[metadata$Type == "exclude"]
    exclude_downloadble <- metadata$Downloadable[metadata$Type == "exclude"]
  } else {
    exclude_data <- NULL
    excludes_params <- NULL # no excludes in project
  }
  
 # Build WTW dataset -----------------------------------------------------------  
  dataset <- new_dataset_from_auto(
    c(theme_data, weight_data, include_data, exclude_data)
  )
  
  # Build the themes_params list -----------------------------------------------
  themes_params <- lapply(unique(theme_groups), function(x) {
    # Get indices for features in this group
    idx <- which(theme_groups == x)
      # Build feature list
      features <- lapply(idx, function(i) {
        if (theme_legend[i] == "manual") {
          legend <- list(
            type = "manual",
            # values = c(as.numeric(trimws(unlist(strsplit(theme_values[i], ","))))),
            colors = c(trimws(unlist(strsplit(theme_colors[i], ",")))),
            labels = c(trimws(unlist(strsplit(theme_labels[i], ","))))
          ) } else {
            legend <- list(
              type = "continuous",
              colors = color_palette(theme_colors[i])
            )
          }
        list(
          name = theme_names[i],
          variable = list(
            index = names(theme_data)[i],
            units = theme_units[i],
            legend = legend,
            provenance = theme_provenance[i]
          ),
          status = TRUE,
          visible = theme_visible[i],
          hidden = theme_hidden[i],
          downloadable = theme_downloadble[i],
          goal = theme_goals[i],
          limit_goal = 0
        )
      })
    list(
      name = x,
      feature = features
    )
  })
  
#  Build the weight_params list ------------------------------------------------
  if(!is.null(weight_data)) {
    weights_params <- lapply(seq_len(terra::nlyr(weight_data)), function(i) {
      # Legend setup
      if (weight_legend[i] == "manual") {
        legend <- list(
          type = "manual",
          colors = trimws(unlist(strsplit(weight_colors[i], ","))),
          labels = trimws(unlist(strsplit(weight_labels[i], ",")))
        )
      } else {
        legend <- list(
          type = "continuous",
          colors = color_palette(weight_colors[i])
        )
      }
      list(
        name = weight_names[i],
        variable = list(
          index = names(weight_data)[i],
          units = weight_units[i],
          legend = legend,
          provenance = theme_provenance[i]
        ),
        status = TRUE,
        visible = weight_visible[i],
        hidden = weight_hidden[i],
        downloadable = weight_downloadble[i],
        factor = 0
      )
    })
  }
  
  #  Build the include_params list ---------------------------------------------
  if (!is.null(include_data)) {
    includes_params <- lapply(seq_len(terra::nlyr(include_data)), function(i) {
      legend <- list(
        type = "manual",
        colors = trimws(unlist(strsplit(include_colors[i], ","))),
        labels = trimws(unlist(strsplit(include_labels[i], ",")))
      )
      list(
        name = include_names[i],
        variable = list(
          index = names(include_data)[i],
          units = include_units[i],
          legend = legend,
          provenance = include_provenance[i]
        ),
        mandatory = FALSE,
        status = TRUE,
        visible = include_visible[i],
        hidden = include_hidden[i],
        downloadable = include_downloadble[i],
        overlap = NA_character_
      )
    })
  }
  
  #  Build the exclude_params list ---------------------------------------------
  if (!is.null(exclude_data)) {
    excludes_params <- lapply(seq_len(terra::nlyr(exclude_data)), function(i) {
      legend <- list(
        type = "manual",
        colors = trimws(unlist(strsplit(exclude_colors[i], ","))),
        labels = trimws(unlist(strsplit(exclude_labels[i], ",")))
      )
      list(
        name = exclude_names[i],
        variable = list(
          index = names(exclude_data)[i],
          units = exclude_units[i],
          legend = legend,
          provenance = exclude_provenance[i]
        ),
        mandatory = FALSE,
        status = TRUE,
        visible = exclude_visible[i],
        hidden = exclude_hidden[i],
        downloadable = exclude_downloadable[i],
        overlap = NA_character_
      )
    })
  }

  # Write WTW project ----------------------------------------------------------
  write_project(
    themes_params = themes_params,
    weights_params = weights_params,
    includes_params = includes_params,
    excludes_params = excludes_params,
    dataset = dataset,
    name = project_name, 
    path = file.path(project_dir, "WTW", "configs.yaml"),
    spatial_path = file.path(project_dir, "WTW", "spatial.tif"),
    attribute_path = file.path(project_dir, "WTW", "attribute.csv.gz"), 
    boundary_path = file.path(project_dir, "WTW", "boundary.csv.gz"),
    mode = "advanced",
    user_groups = groups,
    author_name = author, 
    author_email = email 
  )
  
  # Clear environment ----------------------------------------------------------
  ## Comment these lines below to keep all the objects in the R session
  rm(list=ls())
  gc()
  
}
