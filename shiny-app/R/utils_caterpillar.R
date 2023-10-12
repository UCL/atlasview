#' Generate options for the caterpillar specialty filter
#'
#' @param cooccurring_diseases data.frame, typically from [`get_cooccurring_diseases()`].
#'
#' @return Character vector of specialties, to use in the `"filter"` input box for the Caterpillar
#'   tab
#' @keywords internal
create_specialty_filter <- function(cooccurring_diseases) {
  cooccurring_diseases <- dplyr::select(cooccurring_diseases, .data$specialty_cooccurring_dis)
  cooccurring_diseases <- dplyr::distinct(cooccurring_diseases)
  cooccurring_diseases <- dplyr::arrange(cooccurring_diseases, .data$specialty_cooccurring_dis)
  dplyr::pull(cooccurring_diseases)
}
