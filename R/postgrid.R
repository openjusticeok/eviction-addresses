#' Parse PostGrid Response
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
    stop()
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
