
source("R/fct_init_metadata.R")

create_wtw_metadata <- function(project_dir, natdata_dir) {
  
  TIF_DIR <- file.path(project_dir, "tifs")
  WTW_SPECIES <- file.path(natdata_dir, "WTW_NAT_SPECIES_METADATA.xlsx")
  WTW_PREP <- file.path(natdata_dir, "WTW_NAT_PREP_METADATA.csv")
  
  # Read-in metadata
  ## wtw prep metadata
  wtw_prep_meta <- read.csv(WTW_PREP)
  
  ## wtw species metadata
  sheet_names <- readxl::excel_sheets(WTW_SPECIES)
  wtw_species_meta <- setNames(
    lapply(sheet_names, function(x) readxl::read_excel(WTW_SPECIES, sheet = x)),
    sheet_names
  )
  
  # TIF list
  tif_list <- list.files(TIF_DIR, pattern = "\\.tif$", full.names = TRUE, recursive = TRUE)
  
  # Init output
  df <- init_metadata()
  
  ## Loop over each tiff file:
  for (i in seq_along(tif_list)) {
    
    # Get file names
    tif_path <- tif_list[i]
    tif_base <- tools::file_path_sans_ext(basename(tif_path))
    tif_name <- paste0(tif_base, ".tif")  
    
    # Get metadata associated with the file path and file name
    if (grepl("species/eccc_ch", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$ECCC_CH, File == tif_name)
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, path == "themes/species/eccc_ch")
    } else if (grepl("species/eccc_sar", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$ECCC_SAR, File == tif_name)
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, path == "themes/species/eccc_sar")
    } else if (grepl("species/iucn_amph", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$IUCN_AMPH, File == tif_name)
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, path == "themes/species/iucn_amph")
    } else if (grepl("species/iucn_bird", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$IUCN_BIRD, File == tif_name)
      season <- stringr::str_extract(tif_base, "(?<=_)[0-9]+(?=_)")
      wtw_prep_meta_row <- dplyr::filter(wtw_prep_meta, short_name == paste0("IUCN_BIRD_S", season))
    } else if (grepl("species/iucn_mamm", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$IUCN_MAMM, File == tif_name)
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, path == "themes/species/iucn_mamm")
    } else if (grepl("species/iucn_rept", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$IUCN_REPT, File == tif_name)
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, path == "themes/species/iucn_rept")
    } else if (grepl("species/nsc_end", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$NSC_END, File == tif_name)
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, path == "themes/species/nsc_end")
    } else if (grepl("species/nsc_sar", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$NSC_SAR, File == tif_name)
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, path == "themes/species/nsc_sar")
    } else if (grepl("species/nsc_spp", tif_path)) {
      wtw_species_meta_row <- dplyr::filter(wtw_species_meta$NSC_SPP, File == tif_name)
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, path == "themes/species/nsc_spp")
    } else {
      wtw_species_meta_row <- NULL
      wtw_prep_meta_row    <- dplyr::filter(wtw_prep_meta, wtw_file_name == tif_name)
    }
    
    # Read-in raster
    r <- terra::rast(tif_list[i])
    
    # Get raster stats
    if (!is.factor(r)) {
      ## df
      r_df <- terra::as.data.frame(r, na.rm=TRUE)
      ## number of unique value
      u_values <- nrow(unique(r_df)) |> as.numeric()
      ## max raster value
      max_value <- max(r_df) |> as.numeric() # <- CAN NOT GET MAX ON CATEGORICAL DATA
    }
    
    ## FILE ----------------------------------------------------------------------
    FILE <- tif_name
    
    ## TYPE ----------------------------------------------------------------------
    TYPE <-  dplyr::pull(wtw_prep_meta_row, type)
    
    ## NAME ----------------------------------------------------------------------
    if (is.null(wtw_species_meta_row)) {
      NAME <- dplyr::pull(wtw_prep_meta_row, legend_name)
    } else {
      NAME <- dplyr::pull(wtw_species_meta_row, Common_Name)
    }
    
    ## THEME -------------------------------------------------------------------
    THEME <- dplyr::pull(wtw_prep_meta_row, theme_group_name)
    
    ## LEGEND ------------------------------------------------------------------
    LEGEND <- if (u_values > 2) "continuous" else "manual"
  
    ## VALUES ------------------------------------------------------------------
    if (identical(u_values, 2) && identical(max_value, 1)) {
      VALUES <- "0, 1" # IUCN, NSC, KBA, Includes 
    } else if (identical(u_values, 2)) {
      VALUES <- paste0("0,", max_value) # ECCC: rare case if only 2 unique values
    } else if (identical(u_values, 1)) {
      VALUES <- max_value # covers entire AOI
    } else {
      VALUES <- "" # continuous data does not need values
    }
    
    ## COLOR -------------------------------------------------------------------
    short_name <- dplyr::pull(wtw_prep_meta_row, short_name)
    legend_color <- dplyr::pull(wtw_prep_meta_row, legend_color)
    COLOR <- dplyr::case_when(
      short_name == "ECCC_CH"   & u_values == 2 ~ "#00000000, #756bb1",
      short_name == "ECCC_CH"   & u_values == 1 ~ "#756bb1",
      short_name == "ECCC_CH"   & LEGEND == "continuous" ~ legend_color,
      short_name == "ECCC_SAR"  & u_values == 2 ~ "#00000000, #fb9a99",
      short_name == "ECCC_SAR"  & u_values == 1 ~ "#fb9a99",
      short_name == "ECCC_SAR"  & LEGEND == "continuous" ~ legend_color,
      short_name == "IUCN_AMPH" & u_values == 2 ~ legend_color,
      short_name == "IUCN_AMPH" & u_values == 1 ~ "#a6cee3",
      short_name == "IUCN_BIRD" & u_values == 2 ~ legend_color,
      short_name == "IUCN_BIRD" & u_values == 1 ~ "#ff7f00",
      short_name == "IUCN_MAMM" & u_values == 2 ~ legend_color,
      short_name == "IUCN_MAMM" & u_values == 1 ~ "#b15928",
      short_name == "IUCN_REPT" & u_values == 2 ~ legend_color,
      short_name == "IUCN_REPT" & u_values == 1 ~ "#b2df8a",
      short_name == "NSC_END" & u_values == 2 ~ legend_color,
      short_name == "NSC_END" & u_values == 1 ~ "#4575b4",
      short_name == "NSC_SAR" & u_values == 2 ~ legend_color,
      short_name == "NSC_SAR" & u_values == 1 ~ "#d73027",
      short_name == "NSC_SPP" & u_values == 2 ~ legend_color,
      short_name == "NSC_SPP" & u_values == 1 ~ "#e6f598",
      short_name == "KBA" & u_values == 2 ~ legend_color,
      short_name == "KBA" & u_values == 1 ~ "#1c9099",
      short_name == "CPCAD" & u_values == 2 ~ legend_color,
      short_name == "CPCAD" & u_values == 1 ~ "#7fbc41",
      TRUE ~ legend_color
    )
    
    ## LABELS ------------------------------------------------------------------
    legend_label <- dplyr::pull(wtw_prep_meta_row, legend_label)
    LABELS <- dplyr::case_when(
      short_name == "ECCC_CH"   & u_values == 2 ~ legend_label,
      short_name == "ECCC_CH"   & u_values == 1 ~ "Habitat",
      short_name == "ECCC_SAR"  & u_values == 2 ~ legend_label,
      short_name == "ECCC_SAR"  & u_values == 1 ~ "Range",
      short_name == "IUCN_AMPH" & u_values == 2 ~ legend_label,
      short_name == "IUCN_AMPH" & u_values == 1 ~ "Habitat",
      short_name == "IUCN_BIRD" & u_values == 2 ~ legend_label,
      short_name == "IUCN_BIRD" & u_values == 1 ~ "Habitat",
      short_name == "IUCN_MAMM" & u_values == 2 ~ legend_label,
      short_name == "IUCN_MAMM" & u_values == 1 ~ "Habitat",
      short_name == "IUCN_REPT" & u_values == 2 ~ legend_label,
      short_name == "IUCN_REPT" & u_values == 1 ~ "Habitat",
      short_name == "NSC_END" & u_values == 2 ~ legend_label,
      short_name == "NSC_END" & u_values == 1 ~ "Occurrence",
      short_name == "NSC_SAR" & u_values == 2 ~ legend_label,
      short_name == "NSC_SAR" & u_values == 1 ~ "Occurrence",
      short_name == "NSC_SPP" & u_values == 2 ~ legend_label,
      short_name == "NSC_SPP" & u_values == 1 ~ "Occurrence",
      short_name == "KBA" & u_values == 2 ~ legend_label,
      short_name == "KBA" & u_values == 1 ~ "KBA",
      short_name == "CPCAD" & u_values == 2 ~ legend_label,
      short_name == "CPCAD" & u_values == 1 ~ "included",
      TRUE ~ legend_label
    )    
    
    ## UNITS -------------------------------------------------------------------
    UNIT <- dplyr::pull(wtw_prep_meta_row, unit)
    
    ## PROVENANCE --------------------------------------------------------------
    PROVENANCE <- dplyr::pull(wtw_prep_meta_row, provenance)
    
    ## VISIBLE -----------------------------------------------------------------
    VISIBLE <- dplyr::pull(wtw_prep_meta_row, visible) 
    
    ## HIDDEN ------------------------------------------------------------------
    HIDDEN <- dplyr::pull(wtw_prep_meta_row, hidden)
    
    ## DOWNLOADABLE ------------------------------------------------------------
    DOWNLOADABLE <- dplyr::pull(wtw_prep_meta_row, downloadable)     
    
    ## GOAL --------------------------------------------------------------------
    category <- dplyr::pull(wtw_prep_meta_row, category)
    GOAL <- switch(
      category,
      "species" = dplyr::pull(wtw_species_meta_row, Goal),
      "habitat" = "0.2",
      ""
    )
    
    ## Build new national row ----
    new_row <- c(
      TYPE, 
      THEME, 
      FILE, 
      NAME, 
      LEGEND, 
      VALUES, 
      COLOR, 
      LABELS, 
      UNIT, 
      PROVENANCE,
      VISIBLE, 
      HIDDEN, 
      DOWNLOADABLE, 
      GOAL
    )
      
    ## Append to DF
    df <- structure(rbind(df, new_row), .Names = names(df))
  } 
  
  # Write to csv ----
  write.csv(
    df,
    file.path(project_dir, "wtw/metadata/wtw-metadata.csv"),
    row.names = FALSE
  )
}