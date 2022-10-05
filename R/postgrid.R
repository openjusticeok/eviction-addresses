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
#' @import assertthat
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

  address_method <- switch(
    rlang::check_exclusive(line1, street_number),
    "line1" = "lines",
    "street_number" = "parts"
  )

  assert_that(
    address_method %in% c("lines", "parts")
  )

  if(address_method == "lines") {
    assert_that(
      is.na(street_number),
      is.na(street_direction),
      is.na(street_name),
      is.na(street_type),
      is.na(unit)
    )

    assert_that(
      is.string(line1) && !is.na(line1),
      is.string(line2)
    )

  } else {
    assert_that(
      is.na(line1),
      is.na(line2)
    )

    assert_that(
      is.string(street_number) && !is.na(street_number),
      is.string(street_direction) && !is.na(street_direction),
      is.string(street_name) && !is.na(street_name),
      is.string(street_type) && !is.na(street_type),
      is.string(unit)
    )

    line1 <- stringr::str_c(
      street_number,
      street_direction,
      street_name,
      street_type,
      sep = " "
    )

    line2 <- unit
  }

  assert_that(
    is.string(city) && !is.na(city),
    is.string(state) && !is.na(state),
    is.string(zip) && !is.na(zip),
    is.string(country) && !is.na(country)
  )

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
#' @param config The path of a `config.yml` file with section to be parsed by `config::get(value = "postgrid")`
#' @param address A list with elements `line1`, `line2`, `city`, `provinceOrState`, and `country`
#' @param geocode A flag (logical vector of length one) indicating whether to geocode the address. Uses another Postgrid unit. Defaults to `TRUE`
#'
#' @return A PostGrid response
#'
#' @import assertthat
#'
send_postgrid_request <- function(config = NULL, address = list(), geocode = T) {
  assert_that(
    not_empty(config),
    is.readable(config)
  )

  postgrid_args <- config::get(value = "postgrid", file = config)

  assert_that(
    is.list(address),
    has_name(address, "line1"),
    has_name(address, "line2"),
    has_name(address, "city"),
    has_name(address, "provinceOrState"),
    has_name(address, "country"),
    is.flag(geocode)
  )

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

  parsed_res <- parse_postgrid_response(res)

  return(parsed_res)
}


#' @title Parse PostGrid Response
#'
#' @param res A response from the Postgrid API
#'
#' @return A list with values specified according to the PostGrid documentation
#'
#' @import assertthat
#'
parse_postgrid_response <- function(res) {
  assert_that(
    inherits(res, "response"),
    has_name(res, "status_code"),
    res$status_code == 200L
  )

  body <- httr::content(res, as = "parsed", type = "application/json")
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

  return(parsed_address)
}
