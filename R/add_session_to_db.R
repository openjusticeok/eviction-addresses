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
add_session_to_db <- function(user, sessionid, conn = db) {
  values <- tibble(user = user, sessionid = sessionid, login_time = as.character(now(tzone = "America/Chicago")))
  log_trace("{values}")
  res <- dbWriteTable(
    conn = conn,
    name = Id(schema = "eviction_addresses", table = "session"),
    value = values,
    append = TRUE,
    row.names = F
  )
  log_debug("Wrote session to database table 'session'")
}
