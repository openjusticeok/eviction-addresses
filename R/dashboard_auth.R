#' @title Get Sessions from DB
#' @description Gets a tibble of sessions from the database for use by {shinyauth}
#'
#' @param conn The database connection
#' @param cookie_expiry The cookie expiration
#'
#' @return A tibble of session info
#'
get_sessions_from_db <- function(conn, cookie_expiry = 7) {
  f <- function(expiry = cookie_expiry) {
    logger::log_debug("Getting sessions from db")
    DBI::dbGetQuery(
      conn = conn,
      dbplyr::sql('SELECT * FROM "eviction_addresses"."session"')
    ) |>
      dplyr::mutate(login_time = lubridate::ymd_hms(.data$login_time)) |>
      tibble::as_tibble() |>
      dplyr::filter(.data$login_time > lubridate::now(tzone = "America/Chicago") - lubridate::days(cookie_expiry))
  }
  return(f)
}


#' @title Add Session to DB
#' @description Adds a session to the database for {shinyauth}
#'
#' @param db A database connection Pool
#'
#' @return Returns invisibly if successful
#'
add_session_to_db <- function(db) {
  f <- function(user, sessionid, conn) {
    logger::log_debug("Adding session to db")
    values <- tibble::tibble(
      user = user,
      sessionid = sessionid,
      login_time = as.character(lubridate::now(tzone = "America/Chicago")))
    logger::log_trace("{values}")
    DBI::dbWriteTable(
      conn = db,
      name = DBI::Id(schema = "eviction_addresses", table = "session"),
      value = values,
      append = TRUE,
      row.names = FALSE
    )
    logger::log_debug("Wrote session to database table 'session'")
  }

  return(f)
}


#' @title Get Users from DB
#' @description Gets a tibble of users from the database to be used by {shinyauth}
#'
#' @param db A database connection pool created with `pool::dbPool`
#'
#' @return A tibble of user info
#'
get_users_from_db <- function(db) {
  logger::log_debug("Getting users from db")
  DBI::dbGetQuery(
    db,
    dbplyr::sql('SELECT * FROM "eviction_addresses"."user"')
  ) |>
    tibble::as_tibble()
}
