#' @title Render Document Links
#'
#' @param links A character vector of document links
#'
#' @return An HTML string
#' @export
#'
#' @import assertthat
#'
#' @examples
#'
#' links <- c(
#'   "https://google.com",
#'   "https://google.com"
#' )
#' render_document_links(links)
#'
render_document_links <- function(links) {
  assert_that(
    assertthat::not_empty(links),
    assertthat::noNA(links),
    is.character(links),
    length(links) > 0
  )

  link_template <- stringr::str_c("<a href=\"", "{link}\" ","target=\"_blank\"", ">", "{text}", "</a>")

  html_string <- c()

  for(i in 1:length(links)) {
    stringr::str_c(html_string, "test", sep = "\n")

    html_string[i] <- stringr::str_glue_data(
      list(
        link = links[i],
        text = stringr::str_glue("Document {i}")
      ),
      link_template
    )
  }

  html_string <- stringr::str_flatten(html_string, collapse = "<br>")
  assert_that(
    is.string(html_string)
  )

  return(html_string)
}


#' @title Render HIT Layout
#'
#' @param links A character vector of length greater tha zero, containing HTML links, with no missing values
#' @param layout A file path to a MTurk layout as specified by MTurk documentation
#'
#' @return A string (character vector length one)
#' @export
#'
render_hit_layout <- function(links, layout = NULL) {
  assert_that(
    is.character(links),
    noNA(links)
  )

  if(is.null(layout)) {
    logger::log_debug("No layout file supplied; using layout provided by package")
    layout <- system.file("mturk/layout.html", package = "evictionAddresses")
  }

  assert_that(
    is.readable(layout)
  )

  raw_layout <- readr::read_file(layout)

  document_links_html_block <- render_document_links(links)

  rendered_layout <- stringr::str_glue(raw_layout)

  assert_that(
    is.string(rendered_layout)
  )

  logger::log_debug("Hit layout rendered using supplied links")

  return(rendered_layout)
}


#' @title Render HIT Layout for Case
#'
#' @param db A database pool created with `pool::dbPool`
#' @param case A case id used to render the layout
#' @param layout A file path to an XML layout
#'
#' @return A character string containing an XML layout
#' @export
#'
#' @import assertthat
#'
render_hit_layout_for_case <- function(db, case, layout = NULL) {
  assert_that(
    is.string(case)
  )

  query <- glue::glue_sql(
    "select internal_link from eviction_addresses.\"document\" where \"case\" = {case}",
    .con = db
  )

  res <- DBI::dbGetQuery(
    conn = db,
    statement = query
  )

  document_links <- res$internal_link

  rendered_layout <- render_hit_layout(links = document_links, layout = layout)

  logger::log_debug("Hit layout rendered for case: {case}")

  return(rendered_layout)
}
