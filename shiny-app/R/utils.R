#' Get the path to data files
#' NoRd
get_data_root <- function() {
  Sys.getenv("ATLAS_DATA_PATH")
}

#' Get the full path to a AtlasView data file 
#' @param filename name of a file
#' @NoRd
get_data_filepath <- function(filename) {
  paste(get_data_root(), "/", filename, sep='')
}

#' Load the list of specialties, with their code
#' @NoRd
get_specialties <- function() {
  # list of all specialties
  cbind(
    readr::read_csv(get_data_filepath("lkp_unique_spec_circo_plot.csv"), show_col_types = FALSE), 
    readr::read_csv(get_data_filepath("lkp_unique_spec_circo_plot_codes.csv"), show_col_types = FALSE)
  )
}

#' Get the current UTC time
#' @NoRd
now_utc <- function() {
  now <- Sys.time()
  attr(now, "tzone") <- "UTC"
  now
}
