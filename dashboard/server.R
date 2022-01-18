library(tidyverse)
library(shiny)
library(httr)

# Define server logic required to draw a histogram
function(input, output) {
  
  current_case <- reactive({
    url <- "127.0.0.1:7813/case"
    GET(url)
  })
  
  output$current_case_ui <- renderText(str_c("Current Case: ", content(current_case())))
  
  output$feds_document_ui <- renderText({
    return(paste('<iframe style="height:600px; width:100%" src="', 'http://openjustice.okpolicy.org/wp-content/uploads/sites/4/2021/07/Legal-Representation-and-Eviction-Outcomes-in-Tulsa-County-via-Open-Justice-Oklahoma.pdf', '"></iframe>'))
  })

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
        inputId = "address_street_2",
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
        inputId = "address_submit",
        label = "Submit"
      )
    )
  })
    

}
