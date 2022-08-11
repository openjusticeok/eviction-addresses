#' @title Eviction Addresses Dashboard UI
#' @description The ui function passed to `shinyApp`
#'
#' @return A shiny ui function
#' @export
#'
dashboard_ui <- function() {
  shinydashboard::dashboardPage(
    title = "Open Justice Oklahoma Eviction Addresses",
    skin = "blue",
    shinydashboard::dashboardHeader(
      title = "Eviction Addresses",
      htmltools::tags$li(
        class = "dropdown",
        style = "padding: 8px;",
        shinyauthr::logoutUI("logout")
      ),
      htmltools::tags$li(
        class = "dropdown",
        htmltools::tags$a(
          shiny::icon("github"),
          href = "https://github.com/paulc91/shinyauthr",
          title = "See the code on github"
        )
      ),
      htmltools::tags$li(
        class = "dropdown",
        shiny::actionLink(
          inputId = "header-help",
          label = "Help",
          icon = shiny::icon("question-circle")
        )
      )
    ),
    shinydashboard::dashboardSidebar(
      collapsed = TRUE,
      shinydashboard::sidebarMenuOutput(outputId = "sidebar_menu")
    ),
    shinydashboard::dashboardBody(
      shinyauthr::loginUI(
        "login",
        cookie_expiry = 7
      ),
      shinydashboard::tabItems(
        shinydashboard::tabItem("entry", shiny::uiOutput("entry_ui")),
        shinydashboard::tabItem("metrics", shiny::uiOutput("metrics_ui"))
      )
    )
  )
}
