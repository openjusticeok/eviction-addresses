#' @title Eviction Addresses Dashboard UI
#' @description The ui function passed to `shinyApp`
#'
#' @param cookie_expiry The expiration length for the session cookie
#'
#' @return A shiny ui function
#' @export
#'
#' @examples
dashboard_ui <- function(cookie_expiry) {
  dashboardPage(
    title = "Open Justice Oklahoma Eviction Addresses",
    skin = "blue",
    dashboardHeader(
      title = "Eviction Addresses",
      tags$li(
        class = "dropdown",
        style = "padding: 8px;",
        shinyauthr::logoutUI("logout")
      ),
      tags$li(
        class = "dropdown",
        tags$a(
          icon("github"),
          href = "https://github.com/paulc91/shinyauthr",
          title = "See the code on github"
        )
      ),
      tags$li(
        class = "dropdown",
        actionLink(
          inputId = "header-help",
          label = "Help",
          icon = icon("question-circle")
        )
      )
    ),
    dashboardSidebar(
      collapsed = TRUE,
      sidebarMenuOutput(outputId = "sidebar_menu")
    ),
    dashboardBody(
      shinyauthr::loginUI(
        "login",
        cookie_expiry = cookie_expiry
      ),
      tabItems(
        tabItem("entry", uiOutput("entry_ui")),
        tabItem("metrics", uiOutput("metrics_ui"))
      )
    )
  )
}
