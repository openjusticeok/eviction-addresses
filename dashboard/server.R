library(tidyverse)
library(lubridate)
library(shiny)
library(httr)
library(jsonlite)
library(ojodb)
library(bigrquery)
library(here)
library(googleCloudRunner)
library(googleAuthR)
library(shinydashboard)
library(shinyjs)
library(shinyauthr)

options(gargle_verbosity = "debug")

bigrquery::bq_auth(path = "eviction-addresses-service-account.json")


cr_region_set(region = "us-central1")
cr_project_set("ojo-database")
#cr <- cr_run_get("eviction-addresses-api")
#message(cr$status$url)
#api_url <- cr$status$url
api_url <- "https://eviction-addresses-dashboard-ie5mdr3jgq-uc.a.run.app"
jwt <- cr_jwt_create(api_url)

user_base <- tibble(
  user = c("user1", "user2"),
  password = c("pass1", "pass2"),
  password_hash = sapply(c("pass1", "pass2"), sodium::password_store),
  permissions = c("admin", "standard"),
  name = c("User One", "User Two")
)

# This function must return a data.frame with columns user and sessionid.  Other columns are also okay
# and will be made available to the app after log in.

get_sessions_from_db <- function(conn = db, expiry = cookie_expiry) {
  dbReadTable(conn, "session") |>
    mutate(login_time = ymd_hms(login_time)) |>
    as_tibble() |>
    filter(login_time > now() - days(expiry))
}


# successfully logs in with a password.

add_session_to_db <- function(user, sessionid, conn = db) {
  values <- tibble(user = user, sessionid = sessionid, login_time = as.character(now()))
  dbWriteTable(conn, "session", values, append = TRUE, row.names = F)
}

cookie_expiry <- 7

db <- dbConnect(
  bigrquery::bigquery(),
  project = "ojo-database",
  dataset = "ojo_eviction_addresses"
)
on.exit(dbDisconnect(db))


function(input, output, session) {
  
  # call login module supplying data frame, user and password cols and reactive trigger
  credentials <- shinyauthr::loginServer(
    id = "login",
    data = user_base,
    user_col = user,
    pwd_col = password_hash,
    sodium_hashed = TRUE,
    cookie_logins = TRUE,
    sessionid_col = sessionid,
    cookie_getter = get_sessions_from_db,
    cookie_setter = add_session_to_db,
    log_out = reactive(logout_init())
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
  
  user_info <- reactive({
    credentials()$info
  })
  
  user_data <- reactive({
    req(credentials()$user_auth)
    
    if (user_info()$permissions == "admin") {
      dplyr::starwars[, 1:10]
    } else if (user_info()$permissions == "standard") {
      dplyr::storms[, 1:11]
    }
  })
  
  output$welcome <- renderText({
    req(credentials()$user_auth)
    
    glue("Welcome {user_info()$name}")
  })
  
  output$sidebar_menu <- renderMenu({
    req(credentials()$user_auth)
    sidebarMenu(
      id = "sidebar-menu",
      menuItem(
        "Entry",
        tabName = "entry",
        icon = icon("edit")
      ),
      menuItem(
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
          box(
            width = 12,
            uiOutput("current_case_ui"),
            actionButton(
              inputId = "case_refresh",
              label = "Refresh",
              icon = icon("sync")
            )
          )
        ),
        column(
          width = 8,
          offset = 0,
          box(
            width = 12,
            uiOutput("address_entry_ui")
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          box(
            width = 12,
            div(
              style = "display: flex; justify-content: center; gap: 10px;",
              actionButton(inputId = "previous_document", label = "Previous"),
              textOutput("document_selector_ui"),
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
    
    # fluidRow(
    #   column(
    #     width = 12,
    #     tags$h2(glue("Your permission level is: {user_info()$permissions}.
    #                  You logged in at: {user_info()$login_time}.
    #                  Your data is: {ifelse(user_info()$permissions == 'admin', 'Starwars', 'Storms')}.")),
    #     box(
    #       width = NULL,
    #       status = "primary",
    #       title = ifelse(user_info()$permissions == "admin", "Starwars Data", "Storms Data"),
    #       DT::renderDT(user_data(), options = list(scrollX = TRUE))
    #     )
    #   )
    # )
    
    tabItems(
      tabItem(
        tabName = "entry",
        fluidRow(
          column(
            width = 4,
            box(
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
            box(
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
            box(
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

    con <- dbConnect(
      bigrquery::bigquery(),
      project = "ojo-database",
      dataset = "ojo_eviction_addresses"
    )
    on.exit(dbDisconnect(con))

    dbGetQuery(con, str_c('SELECT t.case FROM `ojo_eviction_addresses.document` t WHERE t.internal_link IS NOT NULL ORDER BY RAND() LIMIT 1')) |>
      pull()
  })
  
  total_cases <- reactive({
    input$case_refresh
    
    con <- dbConnect(
      bigrquery::bigquery(),
      project = "ojo-database",
      dataset = "ojo_eviction_addresses"
    )
    on.exit(dbDisconnect(con))
    
    dbGetQuery(con, glue('SELECT COUNT(*) FROM `ojo_eviction_addresses.case` t LEFT JOIN `ojo-database.ojo_eviction_addresses.address` a ON t.id = a.case WHERE a.id IS NULL')) |>
      pull()
  })

  documents <- reactive({
    current_case <- current_case()

    con <- dbConnect(
      bigrquery::bigquery(),
      project = "ojo-database",
      dataset = "ojo_eviction_addresses"
    )
    on.exit(dbDisconnect(con))

    query <- glue('SELECT * FROM `ojo_eviction_addresses.document` t WHERE t.case = \'{current_case}\'')

    dbGetQuery(con, query)
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
    current_case <- fromJSON(current_case())
    queue <- total_cases()
    div(
      h4(glue("Current case: {current_case$case_number}")),
      h4(glue("{queue} cases in queue"))
    )
  })

  output$current_document_ui <- renderText({
    return(glue('<iframe style="height:600px; width:100%" src="', '{current_document()}', '"></iframe>'))
  })

  
  
  output$total_documents_ui <- renderText(str_c("Total Documents: ", total_documents()))

  output$current_document_num_ui <- renderText(str_c("Current Document: ", current_document_num()))

  output$document_selector_ui <- renderText(str_c(current_document_num(), " / ", total_documents()))
  
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
      ),
      disabled(
        actionButton(
          inputId = "address_submit",
          label = "Submit"
        )
      )
    )
  })
  
  observeEvent(input$address_validate, {
    
    address_entered <- list(
      street_num = isolate(input$address_street_number),
      street_direction = isolate(input$address_street_direction),
      street_name = isolate(input$address_street_name),
      street_type = isolate(input$address_street_type),
      unit = isolate(input$address_street_unit),
      city = isolate(input$address_city),
      state = isolate(input$address_state),
      zip = isolate(input$address_zip)
    )
    
    token <- cr_jwt_token(jwt, api_url)
    url <- str_c(api_url, "/address/validate")
    
    res <- cr_jwt_with_httr(
      POST(
        url,
        body = address_entered,
        encode = "json"
      ),
      token
    )
    validated <- content(res, as = "parsed", encoding = "UTF-8")
    
    message(as.character(validated[[1]]$Address2))

    
    address_entered_string <- str_c(address_entered$street_num,
                                    " ",
                                    address_entered$street_direction,
                                    " ",
                                    address_entered$street_name,
                                    " ",
                                    address_entered$street_type,
                                    " ",
                                    address_entered$street_unit,
                                    " ",
                                    address_entered$city,
                                    ", ",
                                    address_entered$state,
                                    " ",
                                    address_entered$zip)
    
    showModal(modalDialog(
      title = "Confirm",
      h5("Are you sure you want to submit this address?"),
      div(
        h5("Address entered:"),
        h5(address_entered_string)
      ),
      div(
        h5("Verified address:"),
        h5(validated[[1]]$Address2)
      )
    ))
    
  })
}
