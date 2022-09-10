## These constants define valid statuses according to MTurk documentation
## They are used in functions that get statuses
valid_hit_statuses <- c("Assignable", "Unassignable", "Reviewable", "Reviewing", "Disposed")
valid_hit_review_statuses <- c("NotReviewed", "MarkedForReview", "ReviewedAppropriate", "ReviewedInappropriate")
valid_assignment_statuses <- c("Submitted", "Approved", "Rejected")


#' @title MTurk Authentication
#'
#' @param config A file path to a config.yml
#'
#' @return A logical/boolean representing whether we successfully connected to MTurk
#' @export
#'
#' @import assertthat
#'
#' @examples
#'
#' \dontrun{
#' try(mturk_auth())
#' try(mturk_auth(config = "config.yml"))
#' }
#'
mturk_auth <- function(config = NULL) {
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
  assert_that(
    is.flag(check_auth)
  )

  if(check_auth) {
    logger::log_success("pyMTurkR found auth keys")
    return(invisible(T))
  }

  logger::log_error("pyMTurkR didn't find auth keys")
  return(invisible(F))
}


#' @title New HIT Type
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
#' @import assertthat
#'
#' @examples
#'
#' \dontrun{
#' new_hit_type()
#' new_hit_type(reward = "0.20")
#' new_hit_type(duration = pyMTurkR::seconds(minutes = 20))
#' }
#'
new_hit_type <- function(
  title = "eviction-address-transcription",
  description = "Find and transcribe the DEFENDENT'S address from a court document pdf",
  reward = "0.15",
  duration = pyMTurkR::seconds(minutes = 10),
  keywords = "address, text, transcribe, entry, data",
  auto.approval.delay = pyMTurkR::seconds(days = 3),
  ...
) {
  assert_that(
    pyMTurkR::CheckAWSKeys(),
    msg = "AWS keys not available"
  )

  assert_that(
    is.string(title),
    is.string(description),
    is.string(reward),
    is.number(duration),
    is.string(keywords),
    is.number(auto.approval.delay)
  )

  res <- pyMTurkR::CreateHITType(
    title = title,
    description = description,
    reward = reward,
    duration = duration,
    keywords = keywords,
    auto.approval.delay = auto.approval.delay,
    ...
  )

  assert_that(
    has_names(res, c("HITTypeId", "Valid")),
    msg = "The response from pyMTurkR did not succeed or has an unexpected structure"
  )

  valid <- as.logical(res$Valid)

  assert_that(
    is.flag(valid),
    isTRUE(valid)
  )

  assert_that(
    is.string(res$HITTypeId)
  )

  return(res$HITTypeId)
}


#' @title New Case from Queue
#'
#' @param db A database connection pool created with `pool::db`
#'
#' @return A case id from the queue
#' @export
#'
#' @examples
#'
#' \dontrun{
#' new_case_from_queue()
#' }
#'
new_case_from_queue <- function(db) {
  res <- get_case_from_queue(db)

  return(res)
}


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
#' @param db A database pool created with `pool::dbPool`
#' @param case A case id used to render the layout
#' @param layout A file path to an XML layout
#'
#' @return A character string containing an XML layout
#' @export
#'
#' @import assertthat
#'
render_hit_layout <- function(db, case, layout = NULL) {
  assert_that(
    is.string(case)
  )

  if(is.null(layout)) {
    logger::log_debug("No layout file supplied; using layout provided by package")
    layout <- system.file("mturk/layout.html", package = "evictionAddresses")
  }

  assert_that(
    is.readable(layout)
  )

  raw_layout <- readr::read_file(layout)

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

  assert_that(
    is.string(rendered_layout)
  )

  logger::log_debug("Hit layout rendered for case: {case}")

  return(rendered_layout)
}


#' @title New Hit from Case
#'
#' @param case The case id from which to create a new HIT
#' @param hit_type The HIT Type id from which to create a new HIT
#'
#' @return A HIT
#' @export
#'
#' @import assertthat
#'
#' @examples
#'
#' \dontrun{
#' new_hit_from_case(case = "<insert case id>")
#' }
#'
new_hit_from_case <- function(db, case, hit_type = NULL) {
  assert_that(
    is.string(case)
  )

  document_table <- DBI::Id(schema = "eviction_addresses", table = "document")
  hit_table <- DBI::Id(schema = "eviction_addresses", table = "hit")

  hit_layout <- render_hit_layout(db, case)
  mturk_question <- pyMTurkR::GenerateHTMLQuestion(character = hit_layout)

  pyMTurkR::CreateHITWithHITType(
    hit.type = hit_type,
    question = mturk_question,
    expiration = pyMTurkR::seconds(days = 1),
    assignments = "3",
    unique.request.token = uuid::UUIDgenerate(output = "string")
  )
}

#' @title Get HIT Status
#'
#' @param hit The hit id. A string (character vector of length one)
#'
#' @return The HIT status. A string (character vector of length one). See `valid_hit_statuses` for possible values.
#' @export
#'
get_hit_status <- function(hit) {
  assert_that(
    is.string(hit)
  )

  hit_details <- pyMTurkR::status(hit = hit)
  assert_that(
    is.data.frame(hit_details),
    has_name(hit_details, "HITStatus")
  )

  hit_status <- hit_details$HITStatus

  assert_that(
    is.string(hit_status),
    hit_status %in% valid_hit_statuses
  )

  return(tolower(hit_status))
}


#' @title Get HIT Assignments
#'
#' @param hit The HIT id. A string (character vector length one)
#'
#' @return A character vector of Assignment ids
#' @export
#'
get_hit_assignments <- function(hit) {
  assert_that(
    is.string(hit)
  )

  res <- pyMTurkR::GetAssignments(hit = hit)
  assert_that(
    is.data.frame(res),
    length(res) > 0
  )

  assignments <- res$AssignmentId
  assert_that(
    is.character(assignments),
    length(assignments) >= 0,
    noNA(assignments)
  )

  return(assignments)
}


#' @title Get Assignment Status
#'
#' @param assignment The assignment id. A string (character vector length one).
#'
#' @return The assignment status. A string (character vector length one). See `valid_assignment_statuses` for possible values.
#' @export
#'
get_assignment_status <- function(assignment) {
  assert_that(
    is.string(assignment)
  )

  assignment_details <- GetAssignment(assignment)
  assert_that(
    is.data.frame(assignment_details),
    length(assignment_details) > 0
  )

  assignment_status <- assignment_details$AssignmentStatus
  assert_that(
    is.string(assignment_status),
    assignment_status %in% valid_assignment_statuses
  )
}


#' @title Parse HIT Assignment Answer
#'
#' @param answer A data.frame containing the answer for one HIT assignment
#'
#' @return A parsed address ready for validation
#' @export
#'
#' @importFrom rlang .data
#' @import assertthat
#'
parse_assignment_answer <- function(answer) {
  assert_that(
    is.data.frame(answer),
    has_name(answer, "QuestionIdentifier"),
    has_name(answer, "FreeText")
  )

  address <- answer |>
    dplyr::select(.data$QuestionIdentifier, .data$FreeText) |>
    tibble::deframe() |>
    as.list()
  #
  #   line1 <- ""
  #   line2 <- ""
  #   city <- ""
  #   state <- ""
  #   zip <- ""
  #   country <- "us"


}


#' @title Get Assignment Answer
#'
#' @param assignment The Assignment id. A string (character vector length one)
#'
#' @return The parsed assignment as a ??
#' @export
#'
get_assignment_answer <- function(assignment) {
  assert_that(
    is.string(assignment)
  )

  assignment_details <- pyMTurkR::GetAssignment(assignment = assignment, get.answers = T)

  answer <- assignment_details$Answer |>
    parse_assignment_answer()

  return(answer)
}


#' @title Review Assignment
#'
#' @param assignment The Assignment id. A string (character vector length one)
#'
#' @return ??
#' @export
#'
review_assignment <- function(assignment) {

  return()
}


#' @title Compare HIT Assignments
#'
#' @param hit The HIT id for which to compare all assignments
#'
#' @return Nothing
#' @export
#'
#' @import assertthat
#'
#' @examples
#'
#' \dontrun{
#' compare_hit_assignments(hit = "<insert hit id>")
#' }
compare_hit_assignments <- function(hit) {
  assert_that(
    is.string(hit)
  )

  res <- pyMTurkR::GetAssignments(hit = hit, get.answers = T)

  assert_that(
    has_name(res, "Assignments"),
    has_name(res, "Answers"),
    msg = "Could not parse the response from MTurk API: Necessary fields not found"
  )

  assert_that(
    is.data.frame(res$Assignments),
    is.data.frame(res$Answers),
    msg = "Could not parse the response from MTurk API: Fields not returned as data.frame"
  )

  assert_that(
    nrow(res$Assignments) == 3,
    msg = "{nrow(res$Assignments)} retreived. Need 3 to compare. HIT is not ready for review."
  )

  assignments <- res$Assignments
  answers <- res$Answers |>
    split(~AssignmentId)


  return(answers)
}


#' @title Review HIT
#'
#' @param hit The HIT id. A string (character vector length one)
#'
#' @return ??
#' @export
#'
review_hit <- function(hit) {

  return()
}


#' @title Dispose HIT
#'
#' @param hit The HIT id to dispose
#'
#' @return Nothing
#' @export
#'
#' @examples
#'
#' dispose_hit(hit = "<insert hit id>")
#'
dispose_hit <- function(hit = NULL) {

}


#' @title New Sample HIT
#'
#' @return The HIT id. A string (character vector length one)
#' @export
#'
new_sample_hit <- function() {

}
