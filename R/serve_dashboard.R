#' @title Serve Dashboard
#' @description Serves the eviction address entry dashboard
#'
#' @param port The port to serve the dashboard
#'
#' @export
#'
serve_dashboard <- function(config, certs, port = 3838) {
  dashboard_dir <- system.file("shiny/dashboard/", package = "evictionAddresses")
  if (dashboard_dir == "") {
    stop(
      "Could not find the dashboard. Try re-installing `evictionAddresses`.",
      call. = FALSE
    )
  }

  if(!file.exists(config)) {
    stop(
      paste0("Could not find the config file at ", file.path(config))
    )
  }

  file.copy(
    from = file.path(config),
    to = dashboard_dir
  )

  if(!dir.exists(certs)) {
    stop(
      paste0("Could not find the certs directory ", file.path(certs))
    )
  }

  file.copy(
    from = file.path(certs),
    to = dashboard_dir,
    recursive = T
  )

  shiny::runApp(appDir = dashboard_dir, display.mode = "normal", port = port)
}
