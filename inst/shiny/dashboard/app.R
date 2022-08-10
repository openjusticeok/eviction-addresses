library(shiny)

options(gargle_verbosity = "debug")
logger::log_threshold("DEBUG")

googleCloudRunner::cr_region_set(region = "us-central1")
googleCloudRunner::cr_project_set("ojo-database")

cookie_expiry <- 7
connection_args <- config::get('database')

api_url <- "https://eviction-addresses-api-ie5mdr3jgq-uc.a.run.app"

db <- new_db_connection(connection_args)

ui <- dashboard_ui(cookie_expiry)
server <- dashboard_server(connection_args)

shiny::shinyApp(ui, server)
