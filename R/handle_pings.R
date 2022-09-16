#' @title Handle Ping
#' @description A plumber handler for a simple ping of the api
#'
#' @return Empty
#'
handle_ping <- function() {
  f <- function() {
    logger::log_success("pong")

    return("pong")
  }
  return(f)
}


#' @title Handle DB Ping
#' @description A plumber handler that pings the database
#'
#' @param db A database connection pool created with `pool::dbPool`
#'
#' @return Empty
#'
handle_dbping <- function(db) {
  f <- function() {
    test <- DBI::dbGetQuery(db, "SELECT NULL as n")

    log_success("db pong")

    return("db pong")
  }

  return(f)
}


#' @title Handle Future DB Ping
#' @description A plumber handler that pings the database in a background process, returning before returning a response
#'
#' @return Empty
#'
handle_dbpingfuture <- function(db) {
  f <- function() {
    promises::future_promise({
      logger::log_appender(appender_tee("test.log"))

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
  }

  return(f)
}
