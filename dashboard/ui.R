library(shiny)
library(shinydashboard)
library(shinyjs)
library(tidyverse)
library(shinyauthr)

cookie_expiry <- 7

user_base <- tibble(
  user = c("user1", "user2"),
  password = c("pass1", "pass2"),
  password_hash = sapply(c("pass1", "pass2"), sodium::password_store),
  permissions = c("admin", "standard"),
  name = c("User One", "User Two")
)

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
    shinyauthr::loginUI(
      "login", 
      cookie_expiry = cookie_expiry
    ),
    uiOutput("testUI")
  )
)


#   dashboardBody(
#     useShinyjs(),
#     googleAuth_jsUI("auth", login_text = "Test login"),
#     tabItems(
#       tabItem(
#         tabName = "entry",
#         fluidRow(
#           column(
#             width = 8,
#             actionButton(
#               inputId = "case_refresh",
#               label = "Refresh",
#               icon = icon("sync")
#             ),
#             box(
#               textOutput("current_case_ui")
#             ),
#             box(
#               textOutput("total_documents_ui"),
#               actionButton(inputId = "previous_document", label = "Previous"),
#               textOutput("current_document_num_ui"),
#               actionButton(inputId = "next_document", label = "Next")
#             )
#           ),
#           column(
#             width = 3,
#             offset = 1,
#             box(
#               uiOutput("address_validation_ui")
#             )
#           )
#         ),
#         fluidRow(
#           column(
#             width = 8,
#             htmlOutput("current_document_ui")
#           ),
#           column(
#             width = 3,
#             offset = 1,
#             box(
#               uiOutput("address_entry_ui")
#             )
#           )
#         )
#       ),
#       tabItem(
#         tabName = "metrics",
#         fluidRow(
#           column(
#             width = 12
#           )
#         )
#       )
#     )
#   )
# )