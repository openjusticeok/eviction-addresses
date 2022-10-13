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
handle_dbpingfuture <- function(config) {
  f <- function(res) {
    promises::future_promise({
      db <- new_db_pool(config)
      withr::defer(pool::poolClose(db))

      logger::log_appender(logger::appender_stdout())

      test <- DBI::dbGetQuery(db, "SELECT NULL as n")
      logger::log_info("Going to sleep now")
      Sys.sleep(10)
      return()
    },
    seed = TRUE) |>
      promises::then(
        onFulfilled = function(v) {
          logger::log_success("long db pong")
          return()
        },
        onRejected = function(error) {
          logger::log_error("where pong?? no pong >(: {error}")
        }
      )

    msg <- "The request has been queued."
    res$status <- 202

    return(list(success = msg))
  }

  return(f)
}
