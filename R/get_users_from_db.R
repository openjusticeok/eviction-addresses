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
