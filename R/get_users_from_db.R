#' @title Get Users from DB
#' @description Gets a tibble of users from the database to be used by {shinyauth}
#'
#' @param conn The database connection
#'
#' @return A tibble of user info
#' @export
#'
get_users_from_db <- function(conn = db) {
  logger::log_debug("Getting users from db")
  DBI::dbGetQuery(
    conn,
    dbplyr::sql('SELECT * FROM "eviction_addresses"."user"')
  ) |>
    tibble::as_tibble()
}
