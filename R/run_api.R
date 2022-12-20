#' @title Run API
#' @description Starts the eviction address api
#'
#' @param config The path to a configuration file ingested by `{config}`
#' @param ... Additional arguments passed to `plumber::pr_run`, e.g. port = 8080
#' @param .background Whether to start the API in a background process
#'
#' @returns Nothing
#' @export
#'
#' @import plumber
#'
run_api <- function(config, ..., .background = FALSE) {

  logger::log_threshold(logger::TRACE)

  # future::plan(future.callr::callr)

  db <- new_db_pool(config)
  withr::defer(pool::poolClose(db))

  if(.background) {
    future::plan(future.callr::callr)

  } else {
    pr() |>
      pr_handle("GET", "/ping", handle_ping()) |>
      pr_handle("GET", "/dbping", handle_dbping(db)) |>
      pr_handle("GET", "/dbpingfuture", handle_dbpingfuture(config)) |>
      pr_handle("GET", "/refresh", handle_refresh(config)) |>
      pr_handle("GET", "/refresh/queue", handle_refresh_queue(config)) |>
      pr_handle("GET", "/refresh/documents/<n>", handle_refresh_documents(config)) |>
      pr_handle("POST", "/address/validate", handle_address_validate(db, config)) |>
      pr_run(...)
  }

  return()
}
