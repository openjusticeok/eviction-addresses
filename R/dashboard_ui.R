#' @title Eviction Addresses Dashboard UI
#' @description The ui function passed to `shinyApp`
#'
#' @returns A shiny ui function
#'
dashboard_ui <- function() {
  bslib::page_navbar(
    title = "Eviction Addresses",
    bslib::nav_panel(
      title = "Entry",
      shinyauthr::loginUI(
        "login",
        cookie_expiry = 7
      ),
      shiny::uiOutput("entry_ui")
    ),
    bslib::nav_panel(
      title = "Metrics",
      shiny::uiOutput("metrics_ui")
    ),
    bslib::nav_panel(
      title = "Audit",
      shiny::uiOutput("audit_ui")
    ),
    bslib::nav_spacer(),
    bslib::nav_menu(
      title = "Menu",
      align = "right",
      bslib::nav_item(
        htmltools::tags$a(
          shiny::icon("github"),
          shiny::p("Github", style = "display: inline;"),
          href = "https://github.com/openjusticeok/eviction-addresses",
          title = "See the code on github",
        )
      ),
      bslib::nav_item(
        shiny::actionLink(
          inputId = "header-help",
          label = "Help",
          icon = shiny::icon("question-circle")
        )
      ),
      bslib::nav_item(
        shinyauthr::logoutUI("logout", class = "my-1 mx-3 btn-danger")
      )
    )
  )
}
