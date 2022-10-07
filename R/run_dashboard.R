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

# library(shiny)
#
# options(gargle_verbosity = "debug")
# logger::log_threshold("DEBUG")
#
# googleCloudRunner::cr_region_set(region = "us-central1")
# googleCloudRunner::cr_project_set("ojo-database")
#
# cookie_expiry <- 7
# connection_args <- config::get('database')
#
# api_url <- "https://eviction-addresses-api-ie5mdr3jgq-uc.a.run.app"
#
# db <- new_db_pool(connection_args)
#
# ui <- dashboard_ui(cookie_expiry)
# server <- dashboard_server(connection_args)
#
# shiny::shinyApp(ui, server)
