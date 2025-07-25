
create_project_folder <- function(project_dir) {
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
}
