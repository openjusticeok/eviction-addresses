library(tidyverse)
library(shiny)
library(httr)
library(jsonlite)
library(ojodb)
library(bigrquery)
library(here)
library(googleCloudRunner)
library(shinydashboard)
library(shinyjs)

bigrquery::bq_auth(path = here("ojo-database-40842d68fe7b.json"))
  
cr_region_set(region = "us-central1")

cr <- cr_run_get("eviction-addresses-api")
api_url <- cr$status$url
jwt <- cr_jwt_create(api_url)

function(input, output) {
  
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
