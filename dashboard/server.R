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

# googleAuthR::gar_set_client(web_json = "client.json", scopes = c("https://www.googleapis.com/auth/cloud-platform"), activate = "web")

# cr_region_set(region = "us-central1")
# cr_project_set("ojo-database")

bigrquery::bq_auth(path = "client.json")

# cr <- cr_run_get("eviction-addresses-api")
# api_url <- cr$status$url
# jwt <- cr_jwt_create(api_url)

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
              actionButton(
                inputId = "case_refresh",
                label = "Refresh",
                icon = icon("sync")
              ),
              textOutput("current_case_ui")
            )
          ),
          column(
            width = 4,
            box(
              width = 12
            )
          ),
          column(
            width = 4,
            offset = 0,
            box(
              uiOutput("address_validation_ui")
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

    # input$case_refresh
    #
    # url <- "127.0.0.1:8201/case"
    # res <- GET(url)
    # body <- content(res, "text")
    # return(body)
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
    {message("Pressed previous")
    if(current_document_num() <= 1) {
      current_document_num(total_documents())
    } else {
      current_document_num(current_document_num() - 1)
    }}
  )
  observeEvent(
    input$next_document,
    {message("Pressed next")
    if(current_document_num() >= total_documents()) {
      current_document_num(1)
    } else {
      current_document_num(current_document_num() + 1)
    }}
  )

  current_document <- reactive({
    documents <- documents()
    link <- documents[current_document_num(), "internal_link"]
    message(link)
    return(link)
  })

  output$current_case_ui <- renderText(str_c("Current Case: ", current_case()))

  output$current_document_ui <- renderText({
    #return(paste(current_document()))
    return(glue('<iframe style="height:600px; width:100%" src="', '{current_document()}', '"></iframe>'))
  })

  
  
  output$total_documents_ui <- renderText(str_c("Total Documents: ", total_documents()))

  output$current_document_num_ui <- renderText(str_c("Current Document: ", current_document_num()))

  output$document_selector_ui <- renderText(str_c(current_document_num(), " / ", total_documents()))
  
  output$address_entry_ui <- renderUI({
    tagList(
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
      ),
      textInput(
        inputId = "address_street_unit",
        label = "APT/SUITE/UNIT..."
      ),
      textInput(
        inputId = "address_city",
        label = "City"
      ),
      selectInput(
        inputId = "address_state",
        label = "State",
        choices = c("AR", "OK", "TX"),
        selected = "OK"
      ),
      textInput(
        inputId = "address_zip",
        label = "Zip Code"
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

  output$address_validation_ui <- renderUI({
    input$address_validate

    token <- cr_jwt_token(jwt, api_url)
    url <- str_c(api_url, "/address/validate")

    res <- cr_jwt_with_httr(
      POST(
        url,
        body = list(
          street_num = isolate(input$address_street_number),
          street_dir = isolate(input$address_street_direction),
          street_name = isolate(input$address_street_name),
          street_type = isolate(input$address_street_type),
          unit = isolate(input$address_street_unit),
          city = isolate(input$address_city),
          state = isolate(input$address_state),
          zip = isolate(input$address_zip)
        ),
        encode = "json"
      ),
      token
    )
    validated <- content(res, as = "parsed", encoding = "UTF-8")

    renderText(c("Validated: ", as.character(validated[[1]]$Address2)))
  })
}
