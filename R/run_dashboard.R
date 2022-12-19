#' @title Run Dashboard
#' @description Runs the eviction address entry dashboard
#'
#' @param config The path to a config.yml file
#' @param ... Additional arguments passed to `shiny::shinyApp`
#'
#' @export
#'
run_dashboard <- function(config, ...) {
  logger::log_threshold(logger::DEBUG)

  logger::log_debug('Active Configuration: {Sys.getenv("R_CONFIG_ACTIVE")}')

  shiny::shinyApp(
    ui = dashboard_ui,
    server = dashboard_server(config = config),
    options = list(...)
  )
}
