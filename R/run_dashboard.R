#' @title Run Dashboard
#' @description Runs the eviction address entry dashboard
#'
#' @param config The path to a config.yml file
#' @param db A database connection pool created with `pool::dbPool`
#' @param ... Additional arguments passed to `shiny::shinyApp`
#'
#' @export
#'
run_dashboard <- function(config, db, ...) {
  shiny::shinyApp(
    ui = dashboard_ui,
    server = dashboard_server(config),
    onStart = shiny::onStop(function() {
      pool::poolClose(db)
    }),
    ...
  )
}