handle_address_validate <- function(db, config) {
  f <- function(address) {
    res <- send_postgrid_request(config = config, address = address)
    parsed_res <- parse_postgrid_response(res)

    return(parsed_res)
  }

  return(f)
}
