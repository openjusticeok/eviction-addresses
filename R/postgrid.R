#' @title Check Line Arguments
#'
#' @param line1 Line 1 of the address
#' @param line2 Line 2 of the address
#'
#'
check_line_args <- function(line1, line2) {
  if(!is.na(line1)) {
    return(T)
  }

  return(F)
}


#' @title Check Street Arguments
#'
#' @param street_number Street number
#' @param street_direction Street direction
#' @param street_name Street name
#' @param street_type Street type
#' @param unit Unit
#'
check_street_args <- function(street_number, street_direction, street_name, street_type, unit) {
  if(all(
    !is.na(street_number),
    !is.na(street_direction),
    !is.na(street_name),
    !is.na(street_type)
  )) {
    return(T)
  }

  return(F)
}


#' @title Format PostGrid Request
#'
#' @param line1 The first line of an address
#' @param line2 The second line of an address (e.g. unit/suite/apartment)
#' @param city The city of the address
#' @param state The state of the address
#' @param zip The five-digit zip code of the address
#' @param country The two letter country code
#' @param street_number The building number of the address's street
#' @param street_direction The street direction of the address
#' @param street_name The name of the address's street (including post-direction, e.g. 68th E)
#' @param street_type The type of the address's street (e.g. street/avenue/place)
#' @param unit The unit type and value of an address (e.g. APT 13, UNIT C)
#'
#' @return A list with fields suitable for a PostGrid request
#'
format_postgrid_request <- function(
    line1 = NA_character_,
    line2 = NA_character_,
    city = NA_character_,
    state = "ok",
    zip = NA_character_,
    country = "us",
    street_number = NA_character_,
    street_direction = NA_character_,
    street_name = NA_character_,
    street_type = NA_character_,
    unit = NA_character_
  ) {

  if(is.na(city)) {
    logger::log_error("No city supplied to `format_postgrid_request`")
    rlang::abort("Must supply city")
  }

  if(is.na(zip)) {
    logger::log_error("No zip supplied to `format_postgrid_request`")
    rlang::abort("Must supply zip")
  }

  line_check <- check_line_args(line1 = line1, line2 = line2)
  street_check <- check_street_args(
    street_number = street_number,
    street_direction = street_direction,
    street_name = street_name,
    street_type = street_type,
    unit = unit
  )

  if(line_check && street_check) {
    logger::log_error("Both `street_` and `line` variables were supplied. Address specification is ambiguous. Please use only one set of variables.")
    rlang::abort("Must supply only one of either `line` or `street_` variables")
  } else {
    if(line_check) {
      logger::log_debug("Using `line` arguments in `format_postgrid_request`")
      if(any(
        !is.na(street_number),
        !is.na(street_direction),
        !is.na(street_name),
        !is.na(street_type)
      )) {
        logger::log_error("Both `street_` and `line` variables were supplied. Address specification is ambiguous. Please use only one set of variables.")
        rlang::abort("Must supply only one of either `line` or `street_` variables")
      }
    }

    if(street_check) {
      logger::log_debug("Using `street_` arguments in `format_postgrid_request`")

      if(any(
        !is.na(line1),
        !is.na(line2)
      )) {
        logger::log_error("Both `street_` and `line` variables were supplied. Address specification is ambiguous. Please use only one set of variables.")
        rlang::abort("Must supply only one of either `line` or `street_` variables")
      }

      line1 <- stringr::str_c(
        street_number,
        street_direction,
        street_name,
        street_type,
        sep = " "
      )

      if(!is.na(unit)) {
        line2 <- unit
      }
    }

    if(!line_check && !street_check) {
      logger::log_error("`line1` isn't present and at least one `street_` variable is missing")
      rlang::abort("Either `line1` or all of the `street_` variables must be supplied")
    }
  }

  line1 <- stringr::str_squish(line1)

  if(is.na(line2)) {
    line2 <- ""
  }

  address <- list(
    line1 = stringr::str_to_upper(line1),
    line2 = stringr::str_to_upper(line2),
    city = stringr::str_to_upper(city),
    provinceOrState = stringr::str_to_upper(state),
    postalOrZip = stringr::str_to_upper(zip),
    country = stringr::str_to_upper(country)
  )

  return(address)
}


#' @title Send PostGrid Request
#'
#' @param address
#'
#' @return A PostGrid response
#' @export
#'
send_postgrid_request <- function(address = list(), geocode = T) {
  stopifnot(is.list(address))
  stopifnot(rlang::is_scalar_logical(geocode))

  req_body <- list(
    address = address
  ) |>
    jsonlite::toJSON(auto_unbox = T)

  url <- "https://api.postgrid.com/v1/addver/verifications?includeDetails=true"

  if(geocode == T) {
    url <- stringr::str_c(url, "&geocode=true", sep = "")
  }

  res <- httr::POST(
    url,
    httr::add_headers(`x-api-key` = postgrid_args$key),
    httr::content_type_json(),
    httr::accept_json(),
    body = req_body,
    encode = "form"
  )

  return(res)
}


#' @title Parse PostGrid Response
#'
#' @param res
#'
#' @return A list with values specified according to the PostGrid documentation
#' @export
#'
parse_postgrid_response <- function(res) {
  body <- content(res, as = "parsed", type = "application/json")
  if(body$status != "success") {
    log_error("[PostGrid]: {body$status}")
    rlang::abort()
  }

  log_info("[PostGrid]: {body$message}")
  log_info("[PostGrid]: {body$data$status}")

  num_parsing_errors <- length(body$data$errors)
  if(num_parsing_errors != 0) {
    log_error("[PostGrid]: {num_parsing_errors} error(s)")
    log_error("[Postgrid]: {body$data$errors |> unlist()}")
  }

  parsed_address <- list(
    line1 = body$data$line1,
    line2 = body$data$line2,
    streetName = body$data$details$streetName,
    streetType = body$data$details$streetType,
    streetDirection = body$data$details$streetDirection,
    preDirection = body$data$details$preDirection,
    streetNumber = body$data$details$streetNumber,
    suiteID = body$data$details$suiteID,
    suiteKey = body$data$details$suiteKey,
    city = body$data$city,
    county = body$data$details$county,
    state = body$data$provinceOrState,
    country_code = body$data$country,
    country_name = body$data$countryName,
    zip = body$data$postalOrZip,
    zip4 = body$data$zipPlus4,
    lat = body$data$geocodeResult$location$lat,
    lon = body$data$geocodeResult$location$lng,
    geo_accuracy = body$data$geocodeResult$accuracy,
    geo_accuracy_type = body$data$geocodeResult$accuracyType,
    residential = body$data$details$residential,
    vacant = body$data$details$vacant,
    firm_name = body$data$firmName
  )
}
