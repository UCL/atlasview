# DATA #########################################################################

#' Get the full path to a AtlasView data file 
#' @param filename name of a file
#' @noRd
get_data_filepath <- function(filename, root = Sys.getenv("ATLASVIEW_DATA_PATH")) {
  if (root == "") {
    warning("ATLASVIEW_DATA_PATH variable not set, defaulting to `../deployment/atlasview-data/`")
    root <- "../deployment/atlasview-data"
  }
  file.path(root, filename)
}

#' Load, process, and return data for specialties and diseases
#' @importFrom stats setNames
#' @importFrom rlang .data
get_atlasview_data <- function() {
  
  data_root <- Sys.getenv("ATLASVIEW_DATA_PATH")
  
  if (data_root == "") {
    warning("ATLASVIEW_DATA_PATH variable not set, defaulting to `atlasview_mock_data`")
    return(atlasview_mock_data)
  }
  
  specialties <- data.table::fread(
    get_data_filepath("specialties.csv", root = data_root),
    header = TRUE, colClasses = c("character", "character")
  )
  specialties <- dplyr::arrange(specialties, .data$code)

  specialty_colours <- data.table::fread(get_data_filepath("lkp_spe_col.csv", root = data_root),
    header = TRUE, colClasses = c("character", "character")
  )

  specialties <- dplyr::left_join(specialties, specialty_colours, by = "specialty") # for circos plots
  specialty_colours <- setNames(as.character(specialty_colours$color), specialty_colours$specialty) # for caterpillar plots

  # read full MM res in vis format
  MM_res <- data.table::fread(
    file = get_data_filepath("MM_for_circo_network_vis.csv", root = data_root),
    colClasses = list(character = c(1:8, 13), numeric = 9:12)
  )

  MM_res <- dplyr::left_join(MM_res, specialties, by = c("specialty_index_dis" = "specialty"))
  MM_res <- dplyr::rename(MM_res, "specialty_code" = "code")
  MM_res <- dplyr::left_join(MM_res, specialties, by = c("specialty_cooccurring_dis" = "specialty"))
  MM_res <- dplyr::rename(MM_res, "cooccurring_specialty_code" = "code")

  # N of diseases and specialties
  n_dis_spe <- data.table::fread(file = get_data_filepath("MM_2_n.csv", root = data_root))

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


#' Get the co-occurring diseases
#' 
#' Return the co-occurring diseases for a given index disease from the full data set.
#' Used to generate caterpillar and circos plots.
#'
#' @param all_diseases  data.frame containing the the full disease dataset, typically from
#'   `get_atlasview_data()$MM_res`
#' @param index_disease character, the code of the selected input disease
#' @param specialty optional character, the specialty code on which to focus
#' @param specialty_filter optional character vector, when provided, only co-occurring diseases from
#'   within these specialties will be shown
#'
#' @return A subset of the input data for the co-occurring diseases.
#' @keywords internal
get_cooccurring_diseases <- function(all_diseases, index_disease,
                                     specialty = NULL, specialty_filter = NULL) {
  
  out <- dplyr::filter(all_diseases, .data$phecode_index_dis == index_disease)
  
  if (!is.null(specialty)) {
    out <- dplyr::filter(out, .data$specialty_code == specialty)
  }
  if (!is.null(specialty_filter)) {
    out <- dplyr::filter(out, .data$specialty_cooccurring_dis %in% specialty_filter)
  }
  
  # order cooccurring diseases by descending prevalence ratio
  out[order(out$prev_ratio, decreasing = TRUE), ]
}

