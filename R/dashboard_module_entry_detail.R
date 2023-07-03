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
    bslib::value_box(
      value = textOutput("queue")
    ),
    bslib::value_box(
      value = textOutput("current_case_number")
    ),
    #uiOutput(ns("current_case_ui")),
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
    current_case <- jsonlite::fromJSON(current_case())
    queue <- total_cases()

    output$current_case_number <- renderText({
      invalidateLater(1000)
      current_case$case_number
    })
    # output$current_case_ui <- renderUI({
    #   current_case <- jsonlite::fromJSON(current_case())
    #   queue <- total_cases()
    #   div(
    #     h4(glue::glue("Current case: {current_case$case_number}")),
    #     h4(glue::glue("{queue} cases in queue"))
    #   )
    # })
  })
}
