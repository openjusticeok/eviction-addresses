#' @title Metrics Module UI
#'
#' @description UI for the metrics module
#'
#' @param id The module ID
#'
#' @returns The UI for the metrics module
#'
metricsUI <- function(id) {
  ns <- NS(id)
  htmltools::p("Metrics")
}


#' @title Metrics Module Server
#'
#' @description Server for the metrics module
#'
#' @param id The module ID
#'
#' @returns The server for the metrics module
#'
metricsServer <- function(id) {
  moduleServer(id, function(input, output, session) {

  })
}
