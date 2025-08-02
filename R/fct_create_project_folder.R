
create_project_folder <- function(project_dir) {
  # Create folder structure
  suppressWarnings(dir.create(project_dir))
  suppressWarnings(dir.create(file.path(project_dir, "aoi")))
  suppressWarnings((dir.create(file.path(project_dir, "tifs"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "eccc_ch"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "eccc_sar"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "iucn_amph"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "iucn_bird"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "iucn_rept"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "iucn_mamm"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "nsc_end"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "nsc_sar"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "species", "nsc_spp"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "themes", "habitat"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "weights"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "weights", "carbon"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "weights", "climate"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "weights", "connectivity"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "weights", "eservices"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "weights", "pressures"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "weights", "hotspots"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "includes"))))
  suppressWarnings((dir.create(file.path(project_dir, "tifs", "excludes"))))
  suppressWarnings(dir.create(file.path(project_dir, "wtw")))
  suppressWarnings(dir.create(file.path(project_dir, "wtw", "metadata")))
  suppressWarnings(dir.create(file.path(project_dir, "wtw", "runs")))
  suppressWarnings(dir.create(file.path(project_dir, "dataprep")))
  suppressWarnings(dir.create(file.path(project_dir, "dataprep", "national")))
  suppressWarnings(dir.create(file.path(project_dir, "dataprep", "regional")))
  suppressWarnings(dir.create(file.path(project_dir, "dataprep", "tmp")))
  
  # Add csv and save to dataprep
  data.frame(
    conversion_ready_input = "full filepath to input data",
    short_name = "10 characters or less name for variable",
    tif_output = "full filepath with extension to output tif",
    unit = "supported units: m2, ha, km2, m, km and count",
    provenance = "national or regional",
    stringsAsFactors = FALSE
  ) |>
    write.csv(
      file = file.path(project_dir, "dataprep", "dataprep.csv"),
      row.names = FALSE
    )
}
