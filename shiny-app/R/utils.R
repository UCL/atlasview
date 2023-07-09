#' Get the path to data files
#' NoRd
get_data_root <- function() {
  Sys.getenv("ATLASVIEW_DATA_PATH")
}

#' Get the full path to a AtlasView data file 
#' @param filename name of a file
#' @NoRd
get_data_filepath <- function(filename) {
  paste(get_data_root(), "/", filename, sep='')
}

#' load the credentials for users for the app
get_credentials <- function() {
  credentials <- read.csv(file=get_data_filepath("users.csv"), stringsAsFactors = FALSE)
  credentials$is_hashed_password <- TRUE
  credentials$admin <- FALSE
  credentials
}

#' Get the current UTC time
#' @NoRd
now_utc <- function() {
  now <- Sys.time()
  attr(now, "tzone") <- "UTC"
  now
}


make_jwt <- function(username) {
  user_id <- paste0('atlasview_', digest::digest(username, algo="sha1"))
  jwt_list <- list(
    aud="atlasview",
    exp=as.numeric(now_utc() + lubridate::minutes(10)),
    iat=as.numeric(now_utc() - lubridate::minutes(10)),
    iss="remark42",
    user=list(
      name=username,
      id=user_id,
      picture=paste0("https://ui-avatars.com/api/?name=", username_to_initials(username)),
      attrs=list(
        admin=FALSE,
        blocked=FALSE
      )
    )
  )
  
  jti <- digest::digest(jwt_list, algo="sha1")
  jwt_list$jti <- jti
  authentication <- do.call(jose::jwt_claim, jwt_list)
  authentication
}

username_to_initials <- function(username) {
  stringr::str_flatten(substr( stringr::str_split(username, "\\.")[[1]] , start = 1 , stop = 1 ), collapse = "+")
}
