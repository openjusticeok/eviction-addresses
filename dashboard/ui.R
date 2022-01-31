library(shiny)
library(shinydashboard)
library(shinyjs)

dashboardPage(
  title = "Open Justice Oklahoma Eviction Addresses",
  skin = "blue",
  dashboardHeader(
    title = "Eviction Addresses",
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
    useShinyjs(),
    tabItems(
      tabItem(
        tabName = "entry",
        fluidRow(
          column(
            width = 8,
            actionButton(
              inputId = "case_refresh",
              label = "Refresh",
              icon = icon("sync")
            ),
            box(
              textOutput("current_case_ui")
            ),
            box(
              textOutput("total_documents_ui"),
              actionButton(inputId = "previous_document", label = "Previous"),
              textOutput("current_document_num_ui"),
              actionButton(inputId = "next_document", label = "Next")
            )
          ),
          column(
            width = 3,
            offset = 1,
            box(
              uiOutput("address_validation_ui")
            )
          )
        ),
        fluidRow(
          column(
            width = 8,
            htmlOutput("current_document_ui")
          ),
          column(
            width = 3,
            offset = 1,
            box(
              uiOutput("address_entry_ui")
            )
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