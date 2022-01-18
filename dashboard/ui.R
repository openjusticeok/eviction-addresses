library(shinydashboard)

dashboardPage(
  title = "Open Justice Oklahoma Eviction Addresses",
  skin = "blue",
  dashboardHeader(
    title = "Eviction Addresses",
    tags$li(
      actionLink(
        inputId = "header-refresh",
        label = "Refresh",
        icon = icon("sync")
      ),
      class = "dropdown"
    ),
    tags$li(
      actionLink(
        inputId = "header-help",
        label = "Help",
        icon = icon("question-circle")
      ),
      class = "dropdown"
    )
  ),
  dashboardSidebar(
    sidebarMenu(
      id = "sidebar-menu",
      menuItem(
        "Entry",
        tabName = "entry",
        icon = icon("edit")
      ),
      menuItem(
        "Metrics",
        tabName = "metrics",
        icon = icon("chart-bar")
      )
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName = "entry",
        fluidRow(
          column(
            width = 12,
            textOutput("current_case_ui")
          )
        ),
        fluidRow(
          column(
            width = 8,
            htmlOutput("feds_document_ui")
          ),
          column(
            width = 3,
            offset = 1,
            uiOutput("address_entry_ui")
          )
        )
      ),
      tabItem(
        tabName = "metrics",
        fluidRow(
          column(
            width = 12
          )
        )
      )
    )
  )
)