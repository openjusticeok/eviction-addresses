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
library(DBI)
library(logger)
library(glue)
library(pool)
library(odbc)

options(gargle_verbosity = "debug")
log_threshold("INFO")
#bigrquery::bq_auth(path = "eviction-addresses-service-account.json")

cr_region_set(region = "us-central1")
cr_project_set("ojo-database")
#cr <- cr_run_get("eviction-addresses-api")
#message(cr$status$url)
#api_url <- cr$status$url
api_url <- "https://eviction-addresses-api-ie5mdr3jgq-uc.a.run.app"

get_users_from_db <- function(conn = db, expiry = cookie_expiry) {
  dbGetQuery(
  	conn,
  	sql('SELECT * FROM "eviction_addresses"."user"')
  ) |>
    as_tibble()
}

# This function must return a data.frame with columns user and sessionid.  Other columns are also okay
# and will be made available to the app after log in.

get_sessions_from_db <- function(conn = db, expiry = cookie_expiry) {
  dbGetQuery(
  	conn,
  	sql('SELECT * FROM "eviction_addresses"."session"')
  ) |>
    mutate(login_time = ymd_hms(login_time)) |>
    as_tibble() |>
    filter(login_time > now(tzone = "America/Chicago") - days(expiry))
}

add_session_to_db <- function(user, sessionid, conn = db) {
  values <- tibble(user = user, sessionid = sessionid, login_time = as.character(now(tzone = "America/Chicago")))
  log_trace("{values}")
  res <- dbWriteTable(
  	conn = conn,
  	name = Id(schema = "eviction_addresses", table = "session"),
  	value = values,
  	append = TRUE,
  	row.names = F
  )
  log_debug("Wrote session to database table 'session'")
}

cookie_expiry <- 7

Sys.setenv(R_CONFIG_ACTIVE="docker")
connection_args <- config::get('database')

db <- pool::dbPool(odbc::odbc(),
             Driver = connection_args$driver,
             Server = connection_args$server,
             Database = connection_args$database,
             Port = connection_args$port,
             Username = connection_args$uid,
             Password = connection_args$pwd,
             SSLmode = "verify-ca",
             Pqopt = stringr::str_glue(
               "{sslrootcert={{connection_args$ssl.ca}}",
               "sslcert={{connection_args$ssl.cert}}",
               "sslkey={{connection_args$ssl.key}}}",
               .open = "{{",
               .close = "}}",
               .sep = " "
             )
)

function(input, output, session) {
  
  user_base <- get_users_from_db()
  
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
  
  jwt <- reactive({
    invalidateLater(2700000)
    cr_jwt_create(api_url)
  })
  
  user_info <- reactive({
    credentials()$info
  })
  
  user_data <- reactive({
    req(credentials()$user_auth)
    
    if (user_info()$permissions == "admin") {
      log_debug("User has admin priveleges")
    } else if (user_info()$permissions == "standard") {
      log_debug("User has standard permissions")
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
              label = "New Case",
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

    conn <- poolCheckout(db)
    dbBegin(conn)
    
    case <- dbGetQuery(
      conn,
      sql('SELECT q."case" FROM eviction_addresses.queue q LEFT JOIN eviction_addresses."case" c ON q."case" = c."id" LEFT JOIN public."case" pc ON q."case" = pc.id WHERE "success" IS NOT TRUE AND "working" IS NOT TRUE ORDER BY attempts ASC, pc.status DESC, c.date_filed DESC LIMIT 1;')
    )
    query <- glue_sql('UPDATE "eviction_addresses"."queue" SET working = TRUE WHERE "case" = {case}', .con = conn)
    dbExecute(conn, query)
    
    dbCommit(conn)
    poolReturn(conn)
    
    case
  })
  
  total_cases <- reactive({
    input$case_refresh
    
    dbGetQuery(
      db,
      sql('SELECT COUNT(*) FROM "eviction_addresses"."queue" WHERE success = FALSE OR success IS NULL;')
    ) |>
      pull()
    
  })

  documents <- reactive({
    current_case <- current_case()

    query <- glue_sql('SELECT * FROM "eviction_addresses"."document" t WHERE t."case" = {current_case};', .con = db)

    res <- dbGetQuery(db, query)
    
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
    current_case <- fromJSON(current_case() |> pull())
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
      )
    )
  })
  
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
    
    address_entered_string <- str_c(address_entered$street_num,
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
    
    token <- cr_jwt_token(jwt(), api_url)
    url <- str_c(api_url, "/address/validate")

    res <- cr_jwt_with_httr(
      POST(
        url,
        body = address_entered,
        encode = "json"
      ),
      token
    )
    
    modal_content <- div()

    if(res$status_code == 200){
      response_content <- content(res, as = "parsed", encoding = "UTF-8")
      log_debug("Response content: {response_content}")
      
      address_validated <<- response_content |>
        map(as_vector) |>
        map(~ifelse(is_empty(.x), NA_character_, .x))
      log_debug("Address validated: {address_validated}")
      
      log_debug("Is null test: {!is.null(address_validated$line1)}")
      if(!is.null(address_validated$line1)){
        address_validated_string <- str_c(
          str_replace_na(address_validated$line1, ""),
          "<br>",
          str_replace_na(address_validated$line2, ""),
          "<br>",
          str_replace_na(address_validated$city, ""),
          ", ",
          str_replace_na(address_validated$state, ""),
          " ",
          str_replace_na(address_validated$zip, "")
        )
        log_debug("Address string: {address_validated_string}")
        
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
        
        query <- glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)

        dbExecute(
          conn = db,
          statement = query
        )
      }
    } else {
      modal_content <- "Bad response from validation server"
      
      query <- glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)
      
      dbExecute(
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
      stop("Something is wrong. You submitted an address without first validating.")
    } else {
      
      new_row <- tibble(
        case = current_case(),
        street_number = as.character(address_validated$streetNumber),
        street_direction = as.character(address_validated$streetDirection),
        street_name = as.character(address_validated$streetName),
        street_type = as.character(address_validated$streetType),
        city = as.character(address_validated$city),
        state = as.character(address_validated$state),
        zip = as.character(address_validated$zip),
        created_at = now(tzone = "America/Chicago"),
        updated_at = now(tzone = "America/Chicago"),
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
      log_debug("New row: {new_row}")
      
      write_status <- dbWriteTable(
        conn = db,
        name = Id(
          schema = "eviction_addresses",
          table = "address"
        ),
        value = new_row,
        append = T
      )
      
      if(write_status == T) {
        log_debug("Wrote new record in 'address' table")
        
        query <- glue_sql('UPDATE "eviction_addresses"."queue" SET success = TRUE, working = FALSE WHERE "case" = {current_case};', .con = db)
        
        dbExecute(
          conn = db,
          statement = query
        )
        
        log_debug("Set status to success")
        
        removeModal()
        input$case_refresh
      } else {
        log_error("Failed to write the new record to table 'address'")
        
        query <- glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)
        
        update_res <- dbExecute(
          conn = db,
          statement = query
        )
        
        if(update_res == 1) {
          log_debug("Incremented attempts by one")
        } else {
          log_debug("{update_res} rows affected by incrementing attempts")
        }
      }
    }
  })
}
