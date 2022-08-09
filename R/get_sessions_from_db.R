#' @title Get Sessions from DB
#' @description Gets a tibble of sessions from the database for use by {shinyauth}
#'
#' @param conn The database connection
#' @param expiry The cookie expiration
#'
#' @return A tibble of session info
#' @export
#'
get_sessions_from_db <- function(conn = db, expiry = cookie_expiry) {
  dbGetQuery(
    conn,
    sql('SELECT * FROM "eviction_addresses"."session"')
  ) |>
    mutate(login_time = ymd_hms(login_time)) |>
    as_tibble() |>
    filter(login_time > now(tzone = "America/Chicago") - days(expiry))
}
