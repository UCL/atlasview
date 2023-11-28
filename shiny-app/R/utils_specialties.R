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


#' Generate app page title
#' 
#' Generate the app's page title using the selected specialty and index disease
#'
#' @param atlasview_data data.frame containing atlasview data, typically from [`get_atlasview_data()`]
#' @param selected_specialty  character, the selected specialty
#' @param selected_index_disease  character, the selected index disease
#' 
#' @return
#' Character string of the format `"AtlasViews: {specialty} \u2192 {disease}"`
#'
#' @keywords internal
generate_pagetitle <- function(atlasview_data, selected_specialty, selected_index_disease) {
  specialties <- atlasview_data$specialties
  index_diseases <- atlasview_data$index_diseases
  
  which_specialty <- specialties$code == selected_specialty
  which_disease <- index_diseases$phecode_index_dis == selected_index_disease
  
  specialty <- specialties$specialty[which_specialty]
  disease <- index_diseases$phenotype_index_dis[which_disease]
  
  glue::glue("AtlasViews: {specialty} \u2192 {disease}")
}
