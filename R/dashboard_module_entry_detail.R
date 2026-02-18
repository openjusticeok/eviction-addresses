#' @title Entry Detail Module UI
#' @description UI function for the entry detail module
#' 
#' @param id The module ID
#' 
#' @returns The UI function for the entry detail module
#' 
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


#' @title Entry Detail Module Server
#' @description Server function for the entry detail module
#' 
#' @param id The module ID
#' @param current_case The reactive value containing the current case
#' @param total_cases The reactive value containing the total number of cases
#' 
#' @returns The server function for the entry detail module
#'
entryDetailServer <- function(id, current_case, total_cases) {
  moduleServer(id, function(input, output, session) {
    output$current_case_ui <- renderUI({
      case_json <- current_case()
      queue <- total_cases()

      # Handle empty queue - cases unavailable for processing
      if (is.null(case_json) || length(case_json) == 0 || case_json == "") {
        return(div(
          h4("No cases available for processing"),
          h4(glue::glue("{queue} total in queue"))
        ))
      }

      # Parse JSON and display valid case
      current_case <- jsonlite::fromJSON(case_json)
      div(
        h4(glue::glue("Current case: {current_case$case_number}")),
        h4(glue::glue("{queue} cases in queue"))
      )
    })
  })
}
