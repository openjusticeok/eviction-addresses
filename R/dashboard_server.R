#' @title Eviction Addresses Dashboard Server
#' @description Generates the server function passed to `shinyApp`
#'
#' @param config The path to a config file
#'
#' @returns A Shiny server function
#'
#' @import shiny logger
#'
dashboard_server <- function(config) {

  function(input, output, session) {
    logger::log_debug("dashboard_server")

    connection_args <- config::get(
      value = "database",
      file = config
    )
    logger::log_debug("Connection args: {connection_args}")

    db <- new_db_pool(config = config)
    shiny::onStop(function() {
      pool::poolClose(pool = db)
    })
    logger::log_debug("Database connection pool created")

    user_base <- get_users_from_db(db = db)
    logger::log_debug("User base created")

    # call login module supplying data frame, user and password cols and reactive trigger
    credentials <- shinyauthr::loginServer(
      id = "login",
      data = user_base,
      user_col = "user",
      pwd_col = "password_hash",
      sodium_hashed = TRUE,
      cookie_logins = TRUE,
      sessionid_col = "sessionid",
      cookie_getter = get_sessions_from_db(db = db, cookie_expiry = 7),
      cookie_setter = add_session_to_db(db = db),
      log_out = shiny::reactive(logout_init())
    )
    logger::log_debug("Login module created")

    # call the logout module with reactive trigger to hide/show
    logout_init <- shinyauthr::logoutServer(
      id = "logout",
      active = reactive(credentials()$user_auth)
    )
    logger::log_debug("Logout module created")

#    observe({
#      if (credentials()$user_auth) {
#        shinyjs::removeClass(selector = "body", class = "sidebar-collapse")
#      } else {
#        shinyjs::addClass(selector = "body", class = "sidebar-collapse")
#      }
#    })
#    logger::log_debug("Sidebar collapse class added")

    user_info <- reactive({
      credentials()$info
    })
    logger::log_debug("User info reactive created")

    user_data <- reactive({
      req(credentials()$user_auth)

      if (user_info()$role == "admin") {
        logger::log_debug("User has admin priveleges")
      } else if (user_info()$role == "user") {
        logger::log_debug("User has standard role")
      }
    })
    logger::log_debug("User data reactive created")

    current_user <- reactive({
      user_info()$user
    })
    logger::log_debug("Current user reactive created")

    current_case <- reactive({
      input$case_refresh

      case <- get_case_from_queue(db = db)

      case
    })
    logger::log_debug("Current case reactive created")

    total_cases <- reactive({
      input$case_refresh

      queue_length <- get_queue_length(db = db)

      queue_length
    })
    logger::log_debug("Total cases reactive created")

    documents <- reactive({
      current_case <- current_case()

      res <- get_documents_by_case(db = db, id = current_case)

      res
    })
    logger::log_debug("Documents reactive created")

    addressEntryServer("address-entry", config, db, current_case, current_user)
    logger::log_debug("Address entry module created")

    entryDetailServer("entry-detail", current_case, total_cases)
    logger::log_debug("Entry detail module created")

    currentDocumentsServer("current-documents", current_case, db)
    logger::log_debug("Current documents module created")

    output$entry_ui <- renderUI({
      req(credentials()$user_auth)
      list(
        bslib::layout_column_wrap(
          width = 1/2,
          fillable = FALSE,
          entryDetailUI("entry-detail"),
          addressEntryUI("address-entry"),
        ),
        currentDocumentsUI("current-documents")
      )
    })
    logger::log_debug("Entry UI created")

    output$metrics_ui <- renderUI({
      req(credentials()$user_auth)
    })
    logger::log_debug("Metrics UI created")
  }
}
