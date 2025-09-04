#' @title Eviction Addresses Dashboard UI
#' @description The ui function passed to `shinyApp`
#'
#' @returns A shiny ui function
#'
dashboard_ui <- function() {
  shiny::tagList(
    shinyjs::useShinyjs(),
    shiny::div(
      id = "login_page",
      style = "width: 500px; max-width: 100%; margin: 0 auto; padding: 20px;",
      shinyauthr::loginUI("login", cookie_expiry = 7)
    ),
    shiny::div(
      id = "main_content",
      style = "display: none;",
      bslib::page_navbar(
        title = "Eviction Addresses",
        theme = bslib::bs_theme(
          version = 5,
          preset = "flatly"
        ),
        bslib::nav_panel(
          title = "Entry",
          bslib::card(
            entryDetailUI("entry-detail")
          ),
          bslib::card(
            addressEntryUI("address-entry")
          ),
          bslib::card(
            currentDocumentsUI("current-documents")
          )
        ),
        bslib::nav_panel(
          title = "Metrics",
          shiny::uiOutput("metrics_ui")
        ),
        bslib::nav_spacer(),
        bslib::nav_item(shinyauthr::logoutUI("logout")),
        bslib::nav_item(
          htmltools::tags$a(
            shiny::icon("github"),
            href = "https://github.com/openjusticeok/eviction-addresses",
            title = "see the code on github"
          )
        )
      )
    )
  )
}
