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

