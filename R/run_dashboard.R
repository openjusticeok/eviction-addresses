#' @title Run Dashboard
#' @description Runs the eviction address entry dashboard
#'
#' @param config The path to a config.yml file
#' @param ... Additional arguments passed to `shiny::shinyApp`
#'
#' @export
#'
run_dashboard <- function(config, ...) {
  logger::log_info('Active Configuration: {Sys.getenv("R_CONFIG_ACTIVE")}')
  
  db <- new_db_pool(config = config)
  on.exit(pool::poolClose(db), add = TRUE)

  shiny::shinyApp(
    ui = dashboard_ui,
    server = dashboard_server(db = db, config = config),
    options = list(...)
  )
}