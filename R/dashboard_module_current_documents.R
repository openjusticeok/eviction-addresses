#' @title Current Documents Module UI
#'
#' @description
#' This function creates the UI for the current documents module.
#'
#' @param id The id of the module
#'
#' @returns A tagList of the UI
#'
currentDocumentsUI <- function(id) {
  ns <- NS(id)

  tagList(
    div(
      style = "display: flex; justify-content: center; gap: 10px;",
      actionButton(inputId = ns("previous_document"), label = "Previous"),
      textOutput(ns("document_selector_ui")),
      actionButton(inputId = ns("next_document"), label = "Next")
    ),
    htmlOutput(ns("current_document_ui"))
  )
}


#' @title Current Documents Module Server
#' 
#' @description
#' This function creates the server for the current documents module.
#' 
#' @param id The id of the module
#' @param current_case The reactive value containing the current case
#' @param db The database connection
#' 
#' @returns The server function for the current documents module
#' 
currentDocumentsServer <- function(id, current_case, db) {
  moduleServer(id, function(input, output, session) {
    documents <- reactive({
      case_id <- current_case()
      
      # Return empty data frame if no case is available
      if (is.null(case_id) || is.na(case_id)) {
        return(data.frame())
      }
      
      res <- get_documents_by_case(db = db, id = case_id)
      logger::log_debug("Documents retrieved: {res}")
      res
    })
    logger::log_debug("Documents reactive created")

    total_documents <- reactive({
      documents <- documents()
      return(nrow(documents))
    })
    logger::log_debug("Total documents reactive created")

    current_document_num <- reactiveVal(0)
    observeEvent(
      total_documents(),
      {if(total_documents() >= 1) {
        current_document_num(1)
        logger::log_debug("Current document number: {current_document_num()}")
      }}
    )

    observeEvent(
      input$previous_document,
      {if(current_document_num() <= 1) {
        current_document_num(total_documents())
        logger::log_debug("Current document number: {current_document_num()}")
      } else {
        current_document_num(current_document_num() - 1)
        logger::log_debug("Current document number: {current_document_num()}")
      }}
    )

    observeEvent(
      input$next_document,
      {if(current_document_num() >= total_documents()) {
        current_document_num(1)
        logger::log_debug("Current document number: {current_document_num()}")
      } else {
        current_document_num(current_document_num() + 1)
        logger::log_debug("Current document number: {current_document_num()}")
      }}
    )

    current_document <- reactive({
      documents <- documents()
      link <- documents[current_document_num(), "internal_link"]
      return(link)
    })
    logger::log_debug("Current document reactive created")

    output$current_document_num_ui <- renderText(stringr::str_c("Current Document: ", current_document_num()))
    logger::log_debug("Current document number UI created")

    output$total_documents_ui <- renderText(stringr::str_c("Total Documents: ", total_documents()))
    logger::log_debug("Total documents UI created")

    output$current_document_num_ui <- renderText(stringr::str_c("Current Document: ", current_document_num()))
    logger::log_debug("Current document number UI created")

    output$document_selector_ui <- renderText(stringr::str_c(current_document_num(), " / ", total_documents()))
    logger::log_debug("Document selector UI created")

    output$current_document_ui <- renderText({
      return(glue::glue('<iframe style="height:600px; width:100%" src="', '{current_document()}', '"></iframe>'))
    })
    logger::log_debug("Current document UI created")
  })
}
