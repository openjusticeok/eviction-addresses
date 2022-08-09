#' @title Eviction Addresses Dashboard
#' @description A dashboard for eviction address entry
#'
#' @param ... Arguments passed to `shinyApp`
#'
#' @return A Shiny App
#' @export
#'
evictionAddressesDashboard <- function(...) {
  options(gargle_verbosity = "debug")
  log_threshold("DEBUG")

  cr_region_set(region = "us-central1")
  cr_project_set("ojo-database")

  cookie_expiry <- 7
  connection_args <- config::get('database')

  api_url <- "https://eviction-addresses-api-ie5mdr3jgq-uc.a.run.app"

  db <- new_db_connection(connection_args)

  ui <- dashboard_ui(cookie_expiry)
  server <- dashboard_server(connection_args)

  shinyApp(ui, server, ...)
}
