#' @title Add Session to DB
#' @description Adds a session to the database for {shinyauth}
#'
#' @param user The username associated with this session
#' @param sessionid The id to use for this session
#' @param conn The database connection
#'
#' @return Returns invisibly if successful
#' @export
#'
add_session_to_db <- function(db) {
  f <- function(user, sessionid, conn) {
    logger::log_debug("Adding session to db")
    values <- tibble::tibble(
      user = user,
      sessionid = sessionid,
      login_time = as.character(lubridate::now(tzone = "America/Chicago")))
    logger::log_trace("{values}")
    res <- DBI::dbWriteTable(
      conn = db,
      name = DBI::Id(schema = "eviction_addresses", table = "session"),
      value = values,
      append = TRUE,
      row.names = F
    )
    logger::log_debug("Wrote session to database table 'session'")
  }
}
