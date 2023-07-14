# DATA #########################################################################

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

#' Load, process, and return data for specialties and diseases
get_atlasview_data <- function() {
  specialties <- readr::read_csv(get_data_filepath("specialties.csv"), show_col_types = FALSE) %>%
    dplyr::arrange(code)
  
  specialty_colours <- read.csv(get_data_filepath("lkp_spe_col.csv"), header = TRUE)
  
  specialties <- specialties %>% dplyr::left_join(y = specialty_colours, by="specialty")   # for circos plots
  specialty_colours <- setNames(as.character(specialty_colours$color), specialty_colours$specialty)  # for caterpillar plots
  
  #read full MM res in vis format
  MM_res <- data.table::fread(file=get_data_filepath("MM_for_circo_network_vis.csv")) %>% 
    dplyr::left_join(y = specialties, by=c("specialty_index_dis" = "specialty")) %>%
    dplyr::rename("specialty_code" = "code") %>%
    dplyr::left_join(y = specialties, by=c("specialty_cooccurring_dis" = "specialty")) %>%
    dplyr::rename("cooccurring_specialty_code" = "code")
  
  # N of diseases and specialties 
  n_dis_spe <- data.table::fread(file = get_data_filepath("MM_2_n.csv"))
  
  # information about index and co-occurring diseases
  index_diseases <- MM_res %>% 
    dplyr::select(phecode_index_dis, phenotype_index_dis, specialty_index_dis, specialty_code) %>% 
    dplyr::distinct() %>% 
    dplyr::arrange(phenotype_index_dis)
  
  list(
    specialties = specialties,
    specialty_colours = specialty_colours,
    MM_res = MM_res,
    n_dis_spe = n_dis_spe,
    index_diseases = index_diseases
  )
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

get_jwt_token <- function(username) {
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
  xsrf <- jwt$jti
  jwt <- do.call(jose::jwt_claim, jwt_list)
  jwt <- jose::jwt_encode_hmac(jwt, secret=charToRaw(Sys.getenv("REMARK_SECRET")))
  list(JWT=jwt, XSRF=xsrf)
}

username_to_initials <- function(username) {
  stringr::str_flatten(substr( stringr::str_split(username, "\\.")[[1]] , start = 1 , stop = 1 ), collapse = "+")
}
