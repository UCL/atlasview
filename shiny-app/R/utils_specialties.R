#' Get available index diseases for given specialty
#'
#' @param index_diseases data.frame of index diseases
#' @param specialty selected specialty code
#' 
#' @keywords internal
get_index_diseases <- function(index_diseases, specialty) {
  specialty_index_diseases <- dplyr::filter(
    index_diseases,
    .data$specialty_code == specialty
  )

  
  if (nrow(specialty_index_diseases) == 0) {
    return(list())
  }
  
  ## Return available choices for selected specialty as named list with 
  ##   names: phenotype; values: disease code
  split(specialty_index_diseases$phecode_index_dis, specialty_index_diseases$phenotype_index_dis)
}
