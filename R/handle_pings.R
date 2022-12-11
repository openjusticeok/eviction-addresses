#' @title Handle Ping
#' @description A plumber handler for a simple ping of the api
#'
#' @details
#' This endpoint returns a simple "pong" message 
#'
#' @returns A plumber handler that returns a 200 status code and a message that the api is connected
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
#' @details
#' This endpoint returns a simple "db pong" message after pinging the database
#'
#' @param db A database connection pool created with `pool::dbPool`
#'
#' @returns A plumber handler that returns a 200 status code and a message that the database is connected
#'
handle_dbping <- function(db) {
  f <- function() {
    test <- DBI::dbGetQuery(db, "SELECT NULL as n")

    logger::log_success("db pong")

    return("db pong")
  }

  return(f)
}


#' @title Handle Future DB Ping
#' @description A plumber handler that pings the database in a background process, returning before returning a response
#'
#' @param config The path to a configuration file ingested by `{config}`
#' 
#' @returns A plumber handler that returns a 202 status code and a message that the request has been queued
#' 
handle_dbpingfuture <- function(config) {
  f <- function(res) {
    promises::future_promise({
      db <- new_db_pool(config)
      withr::defer(pool::poolClose(db))

      logger::log_appender(logger::appender_tee("/var/log/eviction_addresses.log"))

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
