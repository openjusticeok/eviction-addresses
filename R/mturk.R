#' @title Auth MTurk
#'
#' @param config A file path to a config.yml
#'
#' @return A logical/boolean representing whether we successfully connected to MTurk
#' @export
#'
#' @examples
#'
#' auth_mturk()
#' auth_mturk(config = "config.yml")
#'
auth_mturk <- function(config = NULL) {
  if(!is.null(config)) {
    logger::log_debug("Config file supplied; using config variables")

    aws_config <- config::get("aws", file = config)
    if(is.null(aws_config)) {
      logger::log_error("A config file path was supplied but no aws section found")
      return(invisible(F))
    }

    env_set <- Sys.setenv(
      AWS_ACCESS_KEY_ID = aws_config$key.id,
      AWS_SECRET_ACCESS_KEY = aws_config$key.secret
    )

    if(!all(env_set)) {
      logger::log_error("Failed to set environment variables")
      return(invisible(F))
    }
  } else {
    logger::log_debug("No config file supplied; using env variables")
  }

  check_auth <- pyMTurkR::CheckAWSKeys()
  if(check_auth) {
    logger::log_success("pyMTurkR found auth keys")
    return(invisible(T))
  }

  logger::log_error("pyMTurkR didn't find auth keys")
  return(invisible(F))
}


#' @title Create HIT Type
#'
#' @param title The title for the HIT Type
#' @param description A description to be shown to workers
#' @param reward A string representing amount to be paid for successful completion in USD
#' @param duration The time in seconds that a worker has to complete the assignment
#' @param keywords A string with comma separated terms to be used to search for HITs of this type
#' @param auto.approval.delay The time in seconds after which a completed assignment is auto-approved
#' @param ... Additional arguments passed to `pyMTurkR::CreateHITType()`
#'
#' @return The HIT Type id
#' @export
#'
#' @examples
#'
#' create_hit_type()
#' create_hit_type(reward = "0.20")
#' create_hit_type(duration = pyMTurkR::seconds(minutes = 20))
#'
create_hit_type <- function(
  title = "eviction-address-transcription",
  description = "Find and transcribe the DEFENDENT'S address from a court document pdf",
  reward = "0.15",
  duration = pyMTurkR::seconds(minutes = 10),
  keywords = "address, text, transcribe, entry, data",
  auto.approval.delay = pyMTurkR::seconds(days = 3),
  ...
) {
  hit_type <- pyMTurkR::CreateHITType(
    title = title,
    description = description,
    reward = reward,
    duration = duration,
    keywords = keywords,
    auto.approval.delay = auto.approval.delay,
    ...
  )

  return(hit_type)
}

#' @title Render Document Links
#'
#' @param links A character vector of document links
#'
#' @return An HTML string
#' @export
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
  stopifnot(is.character(links))

  if(length(links) <= 0) {
    stop("Must supply one or more document links as a character vector")
  }

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

  return(html_string)
}

#' @title Render HIT Layout
#'
#' @param case A case id used to render the layout
#' @param layout A file path to an XML layout
#'
#' @return A character string containing an XML layout
#' @export
#'
render_hit_layout <- function(case = NULL, layout = NULL) {
  if(is.null(case)) {
    logger::log_error("A case id must be supplied; got this instead: {case}")
    stop("A case id must be supplied")
  }

  if(is.null(layout)) {
    logger::log_debug("No layout file supplied; using layout provided by package")
    layout <- system.file("mturk/layout.html", package = "evictionAddresses")
  }

  if(!file.exists(layout)) {
    logger::log_error("No file found at: {layout}")
    stop("Could not render layout: No file found at: {layout}")
  }

  raw_layout <- readr::read_file(layout)

  ### Add logic to pull documents by case id

  if(!exists("db")) {
    log_debug("Creating new db pool")
    db <- new_db_connection()
    on.exit({
      pool::poolClose(db)
    })
  }

  query <- glue::glue_sql(
    "select internal_link from eviction_addresses.\"document\" where \"case\" = {case}",
    .con = db
  )

  res <- DBI::dbGetQuery(
    conn = db,
    statement = query
  )

  document_links <- res$internal_link

  document_links_html_block <- render_document_links(document_links)

  rendered_layout <- stringr::str_glue(raw_layout)

  return(rendered_layout)
}


#' @title New Case from Queue
#'
#' @return A case id from the queue
#' @export
#'
#' @examples
#'
#' new_case_from_queue()
#'
new_case_from_queue <- function() {
  queue_table <- DBI::Id(schema = "eviction_addresses", table = "queue")
}


#' @title New Hit from Case
#'
#' @param case The case id from which to create a new HIT
#' @param hit_type The HIT Type id from which to create a new HIT
#'
#' @return A HIT
#' @export
#'
#' @examples
#'
#' new_hit_from_case(case = "<insert case id>")
#'
new_hit_from_case <- function(case, hit_type = NULL) {
  document_table <- DBI::Id(schema = "eviction_addresses", table = "document")
  hit_table <- DBI::Id(schema = "eviction_addresses", table = "hit")

  hit_layout <- render_hit_layout(case)
  mturk_question <- pyMTurkR::GenerateHTMLQuestion(character = hit_layout)

  pyMTurkR::CreateHITWithHITType(
    hit.type = hit_type,
    question = mturk_question,
    expiration = pyMTurkR::seconds(days = 1),
    assignments = "3",
    unique.request.token = uuid::UUIDgenerate(output = "string")
  )
}


#' @title Check All HITs
#'
#' @return Nothing
#' @export
#'
#' @examples
#'
#' check_all_hits()
#'
check_all_hits <- function() {
  reviewable_hits <- pyMTurkR::GetReviewableHITs() |>
    as_tibble()

  pyMTurkR::ListAssignmentsForHIT(get.answers = T)
}


#' @title Compare HIT Assignments
#'
#' @param The HIT id for which to compare all assignments
#'
#' @return Nothing
#' @export
#'
#' @examples
#'
#' compare_hit_assignments(hit = "<insert hit id>")
#'
compare_hit_assignments <- function(hit = NULL) {
  if(is.null(hit) || !is.character(hit))

  hit_assignments <- pyMTurkR::GetAssignments(hit = hit, get.answers = T)
}


#' @title Finalize HIT
#'
#' @param hit The HIT id to finalize
#'
#' @return Nothing
#' @export
#'
#' @examples
#'
#' finalize_hit(hit = "<insert hit id>")
#'
finalize_hit <- function(hit = NULL) {

}
