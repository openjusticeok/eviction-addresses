#' @title Run API
#' @description Starts the eviction address api
#'
#' @param config The path to a configuration file ingested by `{config}`
#' @param ... Additional arguments passed to `plumber::pr_run`, e.g. port = 8080
#' @param .background Whether to start the API in a background process
#'
#' @return Nothing
#' @export
#'
#' @import plumber
run_api <- function(config, ..., .background = F) {

  db <- new_db_pool(config)

  if(.background) {
    future::plan(future.callr::callr)

  } else {
    pr() |>
      pr_handle("GET", "/ping", handle_ping()) |>
      pr_handle("GET", "/dbping", handle_dbping(db)) |>
      pr_handle("GET", "/dbpingfuture", handle_dbpingfuture(db)) |>
      pr_handle("GET", "/refresh", handle_refresh(db)) |>
      pr_handle("GET", "/hydrate", handle_hydrate(db)) |>
      pr_handle("POST", "/address/validate", handle_address_validate(db, config)) |>
      pr_run(...)
  }
}