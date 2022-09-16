#' @title Eviction Addresses Dashboard Server
#' @description Generates the server function passed to `shinyApp`
#'
#' @param config The path to a config file
#'
#' @return A Shiny server function
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

    db <- new_db_pool()
    shiny::onStop(function() {
      pool::poolClose(db)
    })

    user_base <- get_users_from_db(db)

    # call login module supplying data frame, user and password cols and reactive trigger
    credentials <- shinyauthr::loginServer(
      id = "login",
      data = user_base,
      user_col = "user",
      pwd_col = "password_hash",
      sodium_hashed = TRUE,
      cookie_logins = TRUE,
      sessionid_col = "sessionid",
      cookie_getter = get_sessions_from_db(db),
      cookie_setter = add_session_to_db(db),
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

    output$welcome <- renderText({
      req(credentials()$user_auth)

      glue::glue("Welcome {user_info()$name}")
    })

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
              uiOutput("current_case_ui"),
              actionButton(
                inputId = "case_refresh",
                label = "New Case",
                icon = icon("sync")
              )
            )
          ),
          column(
            width = 8,
            offset = 0,
            shinydashboard::box(
              width = 12,
              uiOutput("address_entry_ui")
            )
          )
        ),
        fluidRow(
          column(
            width = 12,
            shinydashboard::box(
              width = 12,
              div(
                style = "display: flex; justify-content: center; gap: 10px;",
                actionButton(inputId = "previous_document", label = "Previous"),
                # textOutput("document_selector_ui"),
                actionButton(inputId = "next_document", label = "Next")
              ),
              htmlOutput("current_document_ui")
            )
          )
        )
      )
    })

    output$metrics_ui <- renderUI({
      req(credentials()$user_auth)
    })

    output$testUI <- renderUI({
      req(credentials()$user_auth)

      tabItems(
        tabItem(
          tabName = "entry",
          fluidRow(
            column(
              width = 4,
              shinydashboard::box(
                width = 12,
                uiOutput("current_case_ui"),
                actionButton(
                  inputId = "case_refresh",
                  label = "Refresh",
                  icon = icon("sync")
                )
              )
            )
          ),
          fluidRow(
            column(
              width = 8,
              shinydashboard::box(
                width = 12,
                div(
                  style = "display: flex; justify-content: center; gap: 10px;",
                  actionButton(inputId = "previous_document", label = "Previous"),
                  textOutput("document_selector_ui"),
                  actionButton(inputId = "next_document", label = "Next")
                ),
                htmlOutput("current_document_ui")
              )
            ),
            column(
              width = 4,
              offset = 0,
              shinydashboard::box(
                width = 12,
                uiOutput("address_entry_ui")
              )
            )
          )
        ),
        tabItem(
          tabName = "metrics",
          fluidRow(
            column(
              width = 12
            )
          )
        )
      )
    })

    current_case <- reactive({
      input$case_refresh

      case <- get_case_from_queue()

      case
    })

    total_cases <- reactive({
      input$case_refresh

      queue_length <- get_queue_length(db)

      queue_length
    })

    documents <- reactive({
      current_case <- current_case()

      res <- get_documents_by_case(current_case)

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

    output$current_case_ui <- renderUI({
      current_case <- jsonlite::fromJSON(current_case() |> dplyr::pull())
      queue <- total_cases()
      div(
        h4(glue::glue("Current case: {current_case$case_number}")),
        h4(glue::glue("{queue} cases in queue"))
      )
    })

    output$current_document_ui <- renderText({
      return(glue::glue('<iframe style="height:600px; width:100%" src="', '{current_document()}', '"></iframe>'))
    })



    output$total_documents_ui <- renderText(stringr::str_c("Total Documents: ", total_documents()))

    output$current_document_num_ui <- renderText(stringr::str_c("Current Document: ", current_document_num()))

    output$document_selector_ui <- renderText(stringr::str_c(current_document_num(), " / ", total_documents()))

    output$address_entry_ui <- renderUI({
      div(
        div(
          style = "display: flex; gap: 10px; justify-content: flex-start; flex-wrap: wrap;",
          textInput(
            inputId = "address_street_number",
            label = "Street Number"
          ),
          textInput(
            inputId = "address_street_direction",
            label = "Street Direction"
          ),
          textInput(
            inputId = "address_street_name",
            label = "Street Name"
          ),
          textInput(
            inputId = "address_street_type",
            label = "Street Type"
          )
        ),
        div(
          style = "display: flex; gap: 10px; justify-content: flex-start; flex-wrap: wrap;",
          textInput(
            inputId = "address_street_unit",
            label = "APT/SUITE/UNIT..."
          )
        ),
        div(
          style = "display: flex; gap: 10px; justify-content: flex-start; flex-wrap: wrap;",
          textInput(
            inputId = "address_city",
            label = "City"
          ),
          selectInput(
            width = "80px",
            inputId = "address_state",
            label = "State",
            choices = c("AR", "OK", "TX"),
            selected = "OK"
          ),
          textInput(
            inputId = "address_zip",
            label = "Zip Code"
          )
        ),
        actionButton(
          inputId = "address_validate",
          label = "Validate"
        )
      )
    })

    address_entered <- NULL
    address_validated <- NULL

    observeEvent(input$address_validate, {

      address_entered <<- list(
        street_num = isolate(input$address_street_number),
        street_direction = isolate(input$address_street_direction),
        street_name = isolate(input$address_street_name),
        street_type = isolate(input$address_street_type),
        unit = isolate(input$address_street_unit),
        city = isolate(input$address_city),
        state = isolate(input$address_state),
        zip = isolate(input$address_zip)
      )

      address_entered_string <- stringr::str_c(address_entered$street_num,
                                      " ",
                                      address_entered$street_direction,
                                      " ",
                                      address_entered$street_name,
                                      " ",
                                      address_entered$street_type,
                                      "<br>",
                                      address_entered$unit,
                                      "<br>",
                                      address_entered$city,
                                      ", ",
                                      address_entered$state,
                                      " ",
                                      address_entered$zip)

      token <- googleCloudRunner::cr_jwt_token(jwt(), api_url)
      url <- stringr::str_c(api_url, "/address/validate")

      res <- googleCloudRunner::cr_jwt_with_httr(
        httr::POST(
          url,
          body = address_entered,
          encode = "json"
        ),
        token
      )

      modal_content <- div()

      if(res$status_code == 200){
        response_content <- httr::content(res, as = "parsed", encoding = "UTF-8")
        logger::log_debug("Response content: {response_content}")

        address_validated <<- response_content |>
          purrr::map(purrr::as_vector) |>
          purrr::map(~ifelse(purrr::is_empty(.x), NA_character_, .x))
        logger::log_debug("Address validated: {address_validated}")

        logger::log_debug("Is null test: {!is.null(address_validated$line1)}")
        if(!is.null(address_validated$line1)){
          address_validated_string <- stringr::str_c(
            stringr::str_replace_na(address_validated$line1, ""),
            "<br>",
            stringr::str_replace_na(address_validated$line2, ""),
            "<br>",
            stringr::str_replace_na(address_validated$city, ""),
            ", ",
            stringr::str_replace_na(address_validated$state, ""),
            " ",
            stringr::str_replace_na(address_validated$zip, "")
          )
          logger::log_debug("Address string: {address_validated_string}")

          modal_content <- div(
            h5("Address successfully validated"),
            div(
              style = "display: flex; pad: 10px; justify-content: space-around;",
              div(
                h5("Address entered:"),
                h5(HTML(address_entered_string))
              ),
              div(
                h5("Verified address:"),
                h5(HTML(address_validated_string))
              )
            ),
            actionButton("address_submit", label = "Submit", icon = icon("upload"))
          )
        } else {
          modal_content <- "Could not validate address."

          query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)

          DBI::dbExecute(
            conn = db,
            statement = query
          )
        }
      } else {
        modal_content <- "Bad response from validation server"

        query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)

        DBI::dbExecute(
          conn = db,
          statement = query
        )
      }

      showModal(modalDialog(
        title = "Address Validation",
        modal_content
      ))

    })

    observeEvent(input$address_submit, {

      current_case <- current_case()

      if(!exists("address_entered") | !exists("address_validated")) {
        rlang::abort("Something is wrong. You submitted an address without first validating.")
      } else {

        new_row <- tibble::tibble(
          case = current_case(),
          street_number = as.character(address_validated$streetNumber),
          street_direction = as.character(address_validated$streetDirection),
          street_name = as.character(address_validated$streetName),
          street_type = as.character(address_validated$streetType),
          city = as.character(address_validated$city),
          state = as.character(address_validated$state),
          zip = as.character(address_validated$zip),
          created_at = lubridate::now(tzone = "America/Chicago"),
          updated_at = lubridate::now(tzone = "America/Chicago"),
          line1 = as.character(address_validated$line1),
          line2 = as.character(address_validated$line2),
          pre_direction = as.character(address_validated$preDirection),
          suite_id = as.character(address_validated$suiteID),
          suite_key = as.character(address_validated$suiteKey),
          county = as.character(address_validated$county),
          country_code = as.character(address_validated$country_code),
          country_name = as.character(address_validated$country_name),
          zip4 = as.character(address_validated$zip4),
          lat = as.character(address_validated$lat),
          lon = as.character(address_validated$lon),
          geo_accuracy = as.character(address_validated$geo_accuracy),
          geo_accuracy_type = as.character(address_validated$geo_accuracy_type),
          residential = as.character(address_validated$residential),
          vacant = as.character(address_validated$vacant),
          firm_name = as.character(address_validated$firm_name),
          method = "manual",
          accuracy = "mailing",
          geo_service = "postgrid"
        )
        logger::log_debug("New row: {new_row}")

        write_status <- DBI::dbWriteTable(
          conn = db,
          name = DBI::Id(
            schema = "eviction_addresses",
            table = "address"
          ),
          value = new_row,
          append = T
        )

        if(write_status == T) {
          logger::log_debug("Wrote new record in 'address' table")

          query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET success = TRUE, working = FALSE WHERE "case" = {current_case};', .con = db)

          DBI::dbExecute(
            conn = db,
            statement = query
          )

          logger::log_debug("Set status to success")

          removeModal()
          input$case_refresh
        } else {
          logger::log_error("Failed to write the new record to table 'address'")

          query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)

          update_res <- DBI::dbExecute(
            conn = db,
            statement = query
          )

          if(update_res == 1) {
            logger::log_debug("Incremented attempts by one")
          } else {
            logger::log_debug("{update_res} rows affected by incrementing attempts")
          }
        }
      }
    })
  }
}
