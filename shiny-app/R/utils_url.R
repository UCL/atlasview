#' Extract Specialty and Index Disease from URL Query
#'
#' @param url The query string. It can have a leading `"?"` or not
#'
#' @keywords internal
parse_url <- function(url) {
  query <- parseQueryString(url)
  
  if (!("disease" %in% names(query))) {
    return(NULL)
  }
  
  split <- stringr::str_split(query[["disease"]], "\\$")[[1]]
  out <- list("specialty" = NULL, "disease" = NULL)
  out[["specialty"]] <- split[1]
  out[["disease"]] <- split[2]
  out
}
