currentDocumentsUI <- function(id) {
  ns <- NS(id)

  div(
    style = "display: flex; justify-content: center; gap: 10px;",
    actionButton(inputId = ns("previous_document"), label = "Previous"),
    textOutput(ns("document_selector_ui")),
    actionButton(inputId = ns("next_document"), label = "Next")
  )
  htmlOutput(ns("current_document_ui"))
}

currentDocumentsServer <- function(id, current_case, db) {
  moduleServer(id, function(input, output, session) {
    documents <- reactive({
      res <- get_documents_by_case(db = db, id = current_case())

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

    output$current_document_num_ui <- renderText(stringr::str_c("Current Document: ", current_document_num()))
    logger::log_debug("Current document number UI created")

    output$total_documents_ui <- renderText(stringr::str_c("Total Documents: ", total_documents()))

    output$current_document_num_ui <- renderText(stringr::str_c("Current Document: ", current_document_num()))

    output$document_selector_ui <- renderText(stringr::str_c(current_document_num(), " / ", total_documents()))

    output$current_document_ui <- renderText({
      return(glue::glue('<iframe style="height:600px; width:100%" src="', '{current_document()}', '"></iframe>'))
    })
  })
}
