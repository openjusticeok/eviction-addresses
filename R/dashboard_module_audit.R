#' @title Audit Module UI
#'
#' @description UI for the audit module
#'
#' @param id The module ID
#'
#' @returns The UI for the audit module
#'
auditUI <- function(id) {
  ns <- NS(id)
  htmltools::p("Audit")
}


#' @title Audit Module Server
#'
#' @description Server for the audit module
#'
#' @param id The module ID
#'
#' @returns The server for the audit module
#'
auditServer <- function(id) {
  moduleServer(id, function(input, output, session) {

  })
}
