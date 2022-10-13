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
handle_refresh <- function(db) {
  f <- function(res) {
    promises::future_promise({
      logger::log_appender(logger::appender_tee("test.log"))

      refresh_cases(db)
      refresh_minutes(db)
      refresh_documents(db)
      refresh_queue(db)

      return()
    },
    seed = TRUE) |>
      promises::then(
        function() {
          logger::log_success("Everything is refreshed")
          return()
        }
      )

    msg <- "The request has been queued."
    res$status <- 200
    return(list(success = msg))
  }

  return(f)
}
