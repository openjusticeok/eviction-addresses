#' @title Handle API Refresh
#' @description Plumber handler for endpoint /refresh
#'
#' @details
#' This endpoint refreshes materialized views and inserts new cases and
#' documents into the eviction_addresses schema. It then updates the work queue
#' based on what it finds.
#'
#' @return A 200 if successful
#'
handle_refresh <- function(config) {
  f <- function(res) {
    promises::future_promise({
      db <- new_db_pool(config)
      withr::defer(pool::poolClose(db))

      logger::log_appender(logger::appender_stdout())

      refresh_cases(db)
      refresh_minutes(db)
      refresh_documents(db)
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
