#' @title Eviction Addresses Dashboard Server
#' @description Generates the server function passed to `shinyApp`
#'
#' @param config The path to a config file
#'
#' @returns A Shiny server function
#'
#' @import shiny shinydashboard
#'
dashboard_server <- function(config) {

  function(input, output, session) {

    gcp_config <- config::get(
      value = "gcp",
      file = config
    )

    api_url <- gcp_config$service_url

    connection_args <- config::get(
      value = "database",
      file = config
    )

    db <- new_db_pool(config = config)
    shiny::onStop(function() {
      pool::poolClose(pool = db)
    })

    user_base <- get_users_from_db(db = db)

    # call login module supplying data frame, user and password cols and reactive trigger
    credentials <- shinyauthr::loginServer(
      id = "login",
      data = user_base,
      user_col = "user",
      pwd_col = "password_hash",
      sodium_hashed = TRUE,
      cookie_logins = TRUE,
      sessionid_col = "sessionid",
      cookie_getter = get_sessions_from_db(db = db),
      cookie_setter = add_session_to_db(db = db),
      log_out = shiny::reactive(logout_init())
    )

    # call the logout module with reactive trigger to hide/show
    logout_init <- shinyauthr::logoutServer(
      id = "logout",
      active = reactive(credentials()$user_auth)
    )

    observe({
      if (credentials()$user_auth) {
        shinyjs::removeClass(selector = "body", class = "sidebar-collapse")
      } else {
        shinyjs::addClass(selector = "body", class = "sidebar-collapse")
      }
    })

    jwt <- reactive({
      invalidateLater(2700000)
      googleCloudRunner::cr_jwt_create(api_url)
    })

    user_info <- reactive({
      credentials()$info
    })

    user_data <- reactive({
      req(credentials()$user_auth)

      if (user_info()$permissions == "admin") {
        logger::log_debug("User has admin priveleges")
      } else if (user_info()$permissions == "standard") {
        logger::log_debug("User has standard permissions")
      }
    })

    addressEntryServer("address-entry")
    entryDetailServer("entry-detail", current_case, total_cases)
    currentDocumentsServer("current-documents", current_case, db)

    output$sidebar_menu <- shinydashboard::renderMenu({
      req(credentials()$user_auth)
      shinydashboard::sidebarMenu(
        id = "sidebar-menu",
        shinydashboard::menuItem(
          "Entry",
          tabName = "entry",
          icon = icon("edit")
        ),
        shinydashboard::menuItem(
          "Metrics",
          tabName = "metrics",
          icon = icon("chart-bar")
        )
      )
    })

    output$entry_ui <- renderUI({
      req(credentials()$user_auth)
      tagList(
        fluidRow(
          column(
            width = 4,
            shinydashboard::box(
              width = 12,
              entryDetailUI("entry-detail")
            )
          ),
          column(
            width = 8,
            offset = 0,
            shinydashboard::box(
              width = 12,
              addressEntryUI("address-entry")
            )
          )
        ),
        fluidRow(
          column(
            width = 12,
            shinydashboard::box(
              width = 12,
              currentDocumentsUI("current-documents")
            )
          )
        )
      )
    })

    output$metrics_ui <- renderUI({
      req(credentials()$user_auth)
    })

    current_case <- reactive({
      input$case_refresh

      case <- get_case_from_queue(db = db)

      case
    })

    total_cases <- reactive({
      input$case_refresh

      queue_length <- get_queue_length(db = db)

      queue_length
    })

    documents <- reactive({
      current_case <- current_case()

      res <- get_documents_by_case(db = db, id = current_case)

      res
    })

    total_documents <- reactive({
      documents <- documents()
      return(nrow(documents))
    })

    current_document_num <- reactiveVal(0)
    observeEvent(
      total_documents(),
      {if(total_documents() >= 1) {
        current_document_num(1)
      }}
    )
    observeEvent(
      input$previous_document,
      {if(current_document_num() <= 1) {
        current_document_num(total_documents())
      } else {
        current_document_num(current_document_num() - 1)
      }}
    )
    observeEvent(
      input$next_document,
      {if(current_document_num() >= total_documents()) {
        current_document_num(1)
      } else {
        current_document_num(current_document_num() + 1)
      }}
    )

    current_document <- reactive({
      documents <- documents()
      link <- documents[current_document_num(), "internal_link"]
      return(link)
    })


    output$current_document_ui <- renderText({
      return(glue::glue('<iframe style="height:600px; width:100%" src="', '{current_document()}', '"></iframe>'))
    })

    output$total_documents_ui <- renderText(stringr::str_c("Total Documents: ", total_documents()))

    output$current_document_num_ui <- renderText(stringr::str_c("Current Document: ", current_document_num()))

    output$document_selector_ui <- renderText(stringr::str_c(current_document_num(), " / ", total_documents()))

  }
}
