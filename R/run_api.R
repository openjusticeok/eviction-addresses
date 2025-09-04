#' @title Run API
#' @description Starts the eviction address api
#'
#' @param config The path to a configuration file ingested by `{config}`
#' @param ... Additional arguments passed to `plumber::pr_run`, e.g. port = 8080
#'
#' @returns Nothing
#' @export
#'
#' @import plumber
#'
run_api <- function(config, ...) {
  db <- new_db_pool(config)
  withr::defer(pool::poolClose(db))

  pr() |>
    pr_handle("GET", "/ping", handle_ping()) |>
    pr_handle("GET", "/dbping", handle_dbping(db)) |>
    pr_handle("GET", "/dbpingfuture", handle_dbpingfuture(db)) |>
    pr_handle("GET", "/refresh", handle_refresh(db)) |>
    pr_handle("GET", "/refresh/queue", handle_refresh_queue(db)) |>
    pr_handle("GET", "/refresh/documents/<n>", handle_refresh_documents(db)) |>
    pr_handle("POST", "/address/validate", handle_address_validate(config)) |>
    pr_run(...)
}
