#' load the credentials for users for the app
get_credentials <- function() {
  credentials <- utils::read.csv(file = get_data_filepath("users.csv"), stringsAsFactors = FALSE)
  credentials$is_hashed_password <- TRUE
  credentials$admin <- FALSE
  credentials
}

#' Get the current UTC time
#' @noRd
now_utc <- function() {
  now <- Sys.time()
  attr(now, "tzone") <- "UTC"
  now
}

get_jwt_token <- function(username) {
  user_id <- paste0("atlasview_", digest::digest(username, algo = "sha1"))
  jwt_list <- list(
    aud = "atlasview",
    exp = as.numeric(now_utc() + lubridate::minutes(10)),
    iat = as.numeric(now_utc() - lubridate::minutes(10)),
    iss = "remark42",
    user = list(
      name = username,
      id = user_id,
      picture = paste0("https://ui-avatars.com/api/?name=", username_to_initials(username)),
      attrs = list(
        admin = FALSE,
        blocked = FALSE
      )
    )
  )

  jti <- digest::digest(jwt_list, algo = "sha1")
  jwt_list$jti <- jti
  xsrf <- jti
  jwt <- do.call(jose::jwt_claim, jwt_list)
  jwt <- jose::jwt_encode_hmac(jwt, secret = charToRaw(Sys.getenv("REMARK_SECRET")))
  list(JWT = jwt, XSRF = xsrf)
}

username_to_initials <- function(username) {
  username_parts <- stringr::str_split(username, "\\.")[[1]]
  initials <- substr(username_parts, start = 1, stop = 1)
  stringr::str_flatten(initials, collapse = "+")
}
