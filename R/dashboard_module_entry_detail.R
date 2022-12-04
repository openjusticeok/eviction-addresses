entryDetailUI <- function(id) {
  ns <- NS(id)
  div(
    uiOutput(ns("current_case_ui")),
    actionButton(
      inputId = "case_refresh",
      label = "New Case",
      icon = icon("sync")
    )
  )
}

entryDetailServer <- function(id, current_case, total_cases) {
  moduleServer(id, function(input, output, session) {
    output$current_case_ui <- renderUI({
      current_case <- jsonlite::fromJSON(current_case())
      queue <- total_cases()
      div(
        h4(glue::glue("Current case: {current_case$case_number}")),
        h4(glue::glue("{queue} cases in queue"))
      )
    })
  })
}
