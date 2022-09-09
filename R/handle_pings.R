#' @title Handle Ping
#' @description A plumber handler for a simple ping of the api
#'
#' @return Empty
#' @export
#'
handle_ping <- function() {
  logger::log_success("pong")
  return()
}


#' @title Handle DB Ping
#' @description A plumber handler that pings the database
#'
#' @param db A database connection pool created with `pool::dbPool`
#'
#' @return Empty
#' @export
#'
handle_dbping <- function(db) {
  test <- DBI::dbGetQuery(db, "SELECT NULL as n")

  log_success("db pong")
  return()
}


#' @title Handle Future DB Ping
#' @description A plumber handler that pings the database in a background process, returning before returning a response
#'
#' @return Empty
#' @export
#'
handle_dbpingfuture <- function() {
  promises::future_promise({
    logger::log_appender(appender_tee("test.log"))

    db <- new_db_pool()
    on.exit(pool::poolClose(db))

    test <- DBI::dbGetQuery(db, "SELECT NULL as n")
    logger::log_info("Going to sleep now")
    Sys.sleep(10)
    return()
  },
  seed = TRUE) |>
    then(
      function() {
        logger::log_success("long db pong")
        return()
      }
    )

  return()
}
