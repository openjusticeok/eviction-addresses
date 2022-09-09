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
  future::plan(future.callr::callr)

  connection_args <- config::get(
    value = "database",
    file = config
  )

  db <- new_db_pool(connection_args)

  if(.background) {

  } else {
    pr() |>
      pr_handle("GET", "/ping", handle_ping) |>
      pr_handle("GET", "/dbping", handle_dbping) |>
      pr_handle("GET", "/dbpingfuture", handle_dbpingfuture) |>
      pr_handle("GET", "/refresh", handle_refresh) |>
      pr_handle("GET", "/hydrate", handle_hydrate) |>
      pr_run(...)
  }
}
