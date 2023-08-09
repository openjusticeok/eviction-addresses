#' @title Entry Detail Module UI
#' @description UI function for the entry detail module
#'
#' @param id The module ID
#'
#' @returns The UI function for the entry detail module
#'
entryDetailUI <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    bslib::card_body(
      bslib::layout_column_wrap(
        width = "250px",
        fill = FALSE,
        bslib::value_box(
          title = "Queue",
          value = shiny::textOutput(ns("queue"))
        ),
        bslib::value_box(
          title = "Current Case",
          value = shiny::textOutput(ns("current_case_number"))
        )
      )
    ),
    bslib::card_body(
      fillable = FALSE,
      shiny::actionButton(
        inputId = "case_refresh",
        label = "New Case",
        icon = shiny::icon("sync")
      )
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
  shiny::moduleServer(id, function(input, output, session) {

    output$current_case_number <- shiny::renderText({
      jsonlite::fromJSON(current_case())$case_number
    })

    output$queue <- shiny::renderText({
      total_cases()
    })

  })
}
