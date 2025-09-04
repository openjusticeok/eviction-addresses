#' @title Eviction Addresses Dashboard UI
#' @description The ui function passed to `shinyApp`
#'
#' @returns A shiny ui function
#'
dashboard_ui <- function() {
  bslib::page_fillable(
    theme = bslib::bs_theme(
      version = 5,
      preset = "flatly"
    ),
    shinyjs::useShinyjs(),
    shiny::tags$head(
      shiny::tags$style(
        shiny::HTML("body { visibility: hidden; }")
      )
    ),
    shiny::conditionalPanel(
      condition = "output.user_is_authenticated == false",
      shinyauthr::loginUI(
        id = "login",
        title = "Please log in",
        cookie_expiry = 7
      )
    ),
    shiny::conditionalPanel(
      condition = "output.user_is_authenticated == true",
      bslib::page_navbar(
        title = "Eviction Addresses",
        id = "main_nav",
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
        bslib::nav_item(
          shinyauthr::logoutUI(
            id = "logout"
          )
        ),
        bslib::nav_item(
          htmltools::tags$a(
            bsicons::bs_icon("github"),
            href = "https://github.com/openjusticeok/eviction-addresses",
            title = "See the code on github"
          )
        )
      )
    )
  )
}
