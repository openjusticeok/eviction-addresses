#' @title Handle API Refresh
#' @description Plumber handler for endpoint /refresh
#'
#' @details
#' This endpoint refreshes materialized views and inserts new cases and
#' documents into the eviction_addresses schema. It then updates the work queue
#' based on what it finds.
#'
#' @param config The path to a configuration file ingested by `{config}`
#'
#' @returns A 200 if successful
#'
handle_refresh <- function(config) {
  f <- function(res) {
    promises::future_promise({
      db <- new_db_pool(config)
      withr::defer(pool::poolClose(db))

      # logger::log_appender(logger::appender_tee("/var/log/eviction_addresses.log"))

      refresh_cases(db)
      refresh_minutes(db)
      refresh_queue(db)

      return()
    },
    seed = TRUE) |>
      promises::then(
        onFulfilled = function(v) {
          logger::log_success("Everything is refreshed")
          return()
        },
        onRejected = function(error) {
          logger::log_error("Failed to complete refresh: {error}")
          return()
        }
      )

    msg <- "The request has been queued."
    res$status <- 202
    return(list(success = msg))
  }

  return(f)
}

#' @title Handle API Refresh Documents
#'
#' @description Plumber handler for endpoint `/refresh/documents/<n>`
#'
#' @details
#' This endpoint refreshes documents in the eviction_addresses schema. It then
#' updates the work queue based on what it finds.
#'
#' @param config The path to a configuration file ingested by `{config}`
#'
handle_refresh_documents <- function(config) {
  f <- function(res, n = 10) {
    promises::future_promise({
      db <- new_db_pool(config)
      withr::defer(pool::poolClose(db))

      # logger::log_appender(logger::appender_tee("/var/log/eviction_addresses.log"))

      refresh_documents(db, n)

      return()
    },
    seed = TRUE) |>
      promises::then(
        onFulfilled = function(v) {
          logger::log_success("Documents refreshed")
          return()
        },
        onRejected = function(error) {
          logger::log_error("Failed to refresh documents: {error}")
          return()
        }
      )

    msg <- "The request has been queued."
    res$status <- 202
    return(list(success = msg))
  }

  return(f)
}


#' @title Handle API Refresh Queue
#'
#' @description Plumber handler for endpoint `/refresh/queue`
#'
#' @details
#' This endpoint refreshes the work queue based on what it finds in the
#' eviction_addresses schema.
#'
#' @param config The path to a configuration file ingested by `{config}`
#'
handle_refresh_queue <- function(config) {
  f <- function(res) {
    promises::future_promise({
      db <- new_db_pool(config)
      withr::defer(pool::poolClose(db))

      #logger::log_appender(logger::appender_tee("/var/log/eviction_addresses.log"))

      refresh_queue(db)

      return()
    },
    seed = TRUE) |>
      promises::then(
        onFulfilled = function(v) {
          logger::log_success("Queue refreshed")
          return()
        },
        onRejected = function(error) {
          logger::log_error("Failed to refresh queue: {error}")
          return()
        }
      )

    msg <- "The request has been queued."
    res$status <- 202
    return(list(success = msg))
  }

  return(f)
}
