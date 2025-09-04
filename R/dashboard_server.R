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

    logout_init <- shinyauthr::logoutServer(
      id = "logout",
      active = shiny::reactive(TRUE)
    )

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

    # Update the logout reactive value when logout occurs
    shiny::observeEvent(
      credentials()$user_auth,
      {
        shinyjs::runjs("document.body.style.visibility = 'visible';")
      },
      once = TRUE
    )

    output$user_is_authenticated <- shiny::reactive({
      isTRUE(credentials()$user_auth)
    })

    shiny::outputOptions(
      output,
      "user_is_authenticated",
      suspendWhenHidden = FALSE
    )

    user_info <- reactive({
      req(credentials()$user_auth)
      credentials()$info
    })

    user_data <- reactive({
      req(credentials()$user_auth)

      if (user_info()$role == "admin") {
        logger::log_debug("User has admin priveleges")
      } else if (user_info()$role == "user") {
        logger::log_debug("User has standard role")
      }
    })

    current_user <- reactive({
      req(credentials()$user_auth)
      user_info()$user
    })

    current_case <- reactive({
      req(credentials()$user_auth)
      input$case_refresh

      case <- get_case_from_queue(db = db)

      case
    })

    total_cases <- reactive({
      req(credentials()$user_auth)
      input$case_refresh

      queue_length <- get_queue_length(db = db)

      queue_length
    })

    documents <- reactive({
      req(credentials()$user_auth)
      current_case <- current_case()

      res <- get_documents_by_case(db = db, id = current_case)

      res
    })

    observeEvent(
      credentials()$user_auth,
      {
        if (credentials()$user_auth) {
          addressEntryServer("address-entry", config, db, current_case, current_user)
          logger::log_debug("Address entry module created")

          entryDetailServer("entry-detail", current_case, total_cases)
          logger::log_debug("Entry detail module created")

          currentDocumentsServer("current-documents", current_case, db)
          logger::log_debug("Current documents module created")
        }
      }
    )

    output$metrics_ui <- renderUI({
      req(credentials()$user_auth)
    })
  }
}
