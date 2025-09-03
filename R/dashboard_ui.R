#' @title Eviction Addresses Dashboard UI
#' @description The ui function passed to `shinyApp`
#'
#' @returns A shiny ui function
#'
dashboard_ui <- function() {
	bslib::page_navbar(
    title = "Eviction Addresses",
    theme = bslib::bs_theme(
      version = 5,
			preset = "cerulean"
		),
		bslib::nav_menu(
  		htmltools::tags$li(
  			class = "dropdown",
  			style = "padding: 8px;",
  			shinyauthr::logoutui("logout")
  		),
  		htmltools::tags$li(
  			class = "dropdown",
  			htmltools::tags$a(
  				shiny::icon("github"),
  				href = "https://github.com/paulc91/shinyauthr",
  				title = "see the code on github"
  			)
  		),

  		shinyauthr::loginui(
  			"login",
  			cookie_expiry = 7
  		)
		),
		bslib::nav_panel(
			title = "Entry",
			bslib::layout_columns(
				col_widths = c(4, 8),
				bslib::card(
					entryDetailUI("entry-detail")
				),
				bslib::card(
					addressEntryUI("address-entry")
				)
			),
			bslib::card(
				currentDocumentsUI("current-documents")
			)
		),
		bslib::nav_panel(
			title = "Metrics",
			shiny::uiOutput("metrics_ui")
		)
  )
}
