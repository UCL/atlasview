#' Get the full path to a AtlasView data file 
#' @param filename name of a file
#' @NoRd
get_data_filepath <- function(filename) {
  home_res <- Sys.getenv("ATLASVIEW_DATA_PATH")
  paste(home_res, "/", filename, sep='')
}

#' Get the full path to a AtlasView data file 
#' @param filename name of a file
#' @NoRd
get_specialties <- function() {
  
  home_res <- Sys.getenv("ATLASVIEW_DATA_PATH")
  
  # list of all specialties
  fpath1 <- paste0(home_res, "/lkp_unique_spec_circo_plot.csv")
  fpath2 <- paste0(home_res, "/lkp_unique_spec_circo_plot_codes.csv")
  
  specialties <- cbind(readr::read_csv(fpath1, show_col_types = FALSE), readr::read_csv(fpath2, show_col_types = FALSE))
  specialties
}