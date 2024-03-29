#' @title Handle Address Validate
#'
#' @param db A database connection pool created by `pool::dbPool()`
#' @param config The path to a `config.yml` file to be ingested by `{config}`
#'
#' @returns A handler function for route /address/validate
#'
handle_address_validate <- function(db, config) {
  f <- function(address) {
    res <- send_postgrid_request(config = config, address = address, geocode = T)

    return(res)
  }

  return(f)
}
