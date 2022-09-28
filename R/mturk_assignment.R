valid_assignment_statuses <- c("Submitted", "Approved", "Rejected")


#' @title Get HIT Assignments
#'
#' @param hit The HIT id. A string (character vector length one)
#'
#' @return A character vector of Assignment ids
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
#'
get_assignment_status <- function(assignment) {
  assert_that(
    is.string(assignment)
  )

  assignment_details <- pyMTurkR::GetAssignment(assignment)
  assert_that(
    is.data.frame(assignment_details),
    length(assignment_details) > 0
  )

  assignment_status <- assignment_details$AssignmentStatus
  assert_that(
    is.string(assignment_status),
    assignment_status %in% valid_assignment_statuses
  )

  return(tolower(assignment_status))
}


#' @title Check Assignment Record Exists
#'
#' @param db
#' @param assignment
#' @param hit
#'
#' @return
#'
check_assignment_record_exists <- function(db, assignment, hit) {
  query <- glue::glue_sql(
    'SELECT exists(select 1 from eviction_addresses.assignment where assignment_id={assignment} and hit={hit}',
    .con = db
  )

  res <- DBI::dbExecute(db, query)
}


#' @title New Assignment Record
#'
#' @param db
#' @param assignment
#' @param worker
#'
#' @return
#'
new_assignment_record <- function(db, hit, assignment, worker, status) {
  assignment_table <- DBI::Id(schema = "eviction_addresses", table = "assignment")

  a <- data.frame(
    assignment_id = assignment,
    hit = hit,
    attempts = 0L,
    created_at = lubridate::now(),
    worker = worker,
    status = status
  )

  res <- dbAppendTable(
    conn = db,
    assignment_table,
    value = a
  )
}


#' @title Update Assignment Record
#'
#' @param db
#' @param assignment
#'
#' @return
#'
update_assignment_record <- function(db, assignment, status, answer = NULL) {
  assert_that(
    is.string(assignment),
    is.string(status),
    stringr::str_to_title(status) %in% valid_assignment_statuses
  )

  assignment_table <- DBI::Id(schema = "eviction_addresses", table = "assignment")

  status <- stringr::str_to_lower(status)

  if(is.null(answer)) {
    query <- glue::glue_sql(
      'UPDATE eviction_addresses."assignment" SET status = {status} WHERE assignment_id = {assignment};',
      .con = db
    )
  } else {
    ## Insert answer argument checks

    query <- glue::glue_sql(
      'UPDATE eviction_addresses."assignment" SET status = {status}, answer = {answer} WHERE assignment_id = {assignment};',
      .con = db
    )
  }

  res <- DBI::dbExecute(db, query)

  assert_that(
    is.count(res)
  )

  return()
}


#' @title Parse HIT Assignment Answer
#'
#' @param answer A data.frame containing the answer for one HIT assignment
#'
#' @return A parsed address ready for validation
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

  assert_that(
    is.list(address),
    has_names(address, c("line1", "line2", "city", "state", "zip"))
  )

  address <- format_postgrid_request(
    line1 = address$line1,
    line2 = address$line2,
    city = address$city,
    state = address$state,
    zip = address$zip
  )

  return(address)
}


#' @title Get Assignment Answer
#'
#' @param assignment The Assignment id. A string (character vector length one)
#'
#' @return The parsed assignment as a ??
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
#' @return If successful, True
#'
review_assignment <- function(db, config, assignment) {

  assignment_status <- get_assignment_status(assignment = assignment)
  if(assignment_status == "submitted") {

    answer <- get_assignment_answer(assignment = assignment)
    res <- tryCatch(
      send_postgrid_request(config = config, address = answer, geocode = T),
      error = function(err) {
        update_assignment_record(
          db = db,
          assignment = assignment,
          status = "rejected"
        )
        return(F)
      }
    )

    update_assignment_record(
      db = db,
      assignment = assignment,
      status = "approved",
      answer = res
    )

    return(T)
  }

  return(F)
}


#' @title Compare HIT Assignments
#'
#' @param hit The HIT id for which to compare all assignments
#'
#' @return Nothing
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


#' @title Review HIT Assignments
#'
#' @param hit The HIT id
#'
review_hit_assignments <- function(db, config, hit) {
  assignments <- get_hit_assignments(hit = hit)

  if(length(assignments) < 1) {
    return(NULL)
  }

  reviewed_answers <- list()

  for(i in 1:seq_along(assignments)) {
    status <- get_assignment_status(assignments[i])
    assert_that(
      status %in% tolower(valid_assignment_statuses)
    )
    if(status == "submitted") {
      res <- review_assignment(db = db, config = config, assignment = assignments[i])
      if(!is.null(res)) {

      }
    } else if(status == "accepted") {

    }

    return(NULL)
  }


  return(reviewed_answers)
}

