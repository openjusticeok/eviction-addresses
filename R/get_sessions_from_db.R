#' @title Get Sessions from DB
#' @description Gets a tibble of sessions from the database for use by {shinyauth}
#'
#' @param conn The database connection
#' @param expiry The cookie expiration
#'
#' @return A tibble of session info
#' @export
#'
get_sessions_from_db <- function(conn, cookie_expiry = 7) {
  f <- function(expiry = cookie_expiry) {
    logger::log_debug("Getting sessions from db")
    DBI::dbGetQuery(
      conn = conn,
      dbplyr::sql('SELECT * FROM "eviction_addresses"."session"')
    ) |>
      dplyr::mutate(login_time = lubridate::ymd_hms(login_time)) |>
      tibble::as_tibble() |>
      dplyr::filter(login_time > lubridate::now(tzone = "America/Chicago") - lubridate::days(expiry))
  }
  return(f)
}
