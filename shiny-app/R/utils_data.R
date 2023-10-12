# DATA #########################################################################

#' Get the path to data files
#' @noRd
get_data_root <- function() {
  out <- Sys.getenv("ATLASVIEW_DATA_PATH") 
  if (out == "") {
    warning("ATLASVIEW_DATA_PATH variable not set, defaulting to `../deployment/atlasview-data`")
    out <- file.path("../deployment/atlasview-data")
  }
  out
}

#' Get the full path to a AtlasView data file 
#' @param filename name of a file
#' @noRd
get_data_filepath <- function(filename) {
  paste(get_data_root(), "/", filename, sep = "")
}

#' Load, process, and return data for specialties and diseases
#' @importFrom stats setNames
#' @importFrom rlang .data
get_atlasview_data <- function() {
  specialties <- data.table::fread(
    get_data_filepath("specialties.csv"),
    header = TRUE, colClasses = c("character", "character")
  )
  specialties <- dplyr::arrange(specialties, .data$code)

  specialty_colours <- data.table::fread(get_data_filepath("lkp_spe_col.csv"),
    header = TRUE, colClasses = c("character", "character")
  )

  specialties <- dplyr::left_join(specialties, specialty_colours, by = "specialty") # for circos plots
  specialty_colours <- setNames(as.character(specialty_colours$color), specialty_colours$specialty) # for caterpillar plots

  # read full MM res in vis format
  MM_res <- data.table::fread(
    file = get_data_filepath("MM_for_circo_network_vis.csv"),
    colClasses = list(character = c(1:8, 13), numeric = 9:12)
  )

  MM_res <- dplyr::left_join(MM_res, specialties, by = c("specialty_index_dis" = "specialty"))
  MM_res <- dplyr::rename(MM_res, "specialty_code" = "code")
  MM_res <- dplyr::left_join(MM_res, specialties, by = c("specialty_cooccurring_dis" = "specialty"))
  MM_res <- dplyr::rename(MM_res, "cooccurring_specialty_code" = "code")

  # N of diseases and specialties
  n_dis_spe <- data.table::fread(file = get_data_filepath("MM_2_n.csv"))

  # information about index and co-occurring diseases
  index_diseases <- dplyr::select(
    MM_res,
    .data$phecode_index_dis,
    .data$phenotype_index_dis,
    .data$specialty_index_dis,
    .data$specialty_code
  )
  index_diseases <- dplyr::arrange(dplyr::distinct(index_diseases), .data$phenotype_index_dis)

  list(
    specialties = specialties,
    specialty_colours = specialty_colours,
    MM_res = MM_res,
    n_dis_spe = n_dis_spe,
    index_diseases = index_diseases
  )
}
