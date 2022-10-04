valid_assignment_statuses <- c("Submitted", "Approved", "Rejected")


#' @title Get HIT Assignments
#'
#' @param db A database connection pool
#' @param hit The HIT id. A string (character vector length one)
#'
#' @return A character vector of Assignment ids
#'
get_hit_assignments <- function(db, hit) {
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

  for (i in seq_along(assignments)) {
    if (!assignment_record_exists(db, assignments[i])) {
      new_assignment_record(
        db = db,
        hit = hit,
        assignment = assignments[i],
        status = get_assignment_status(assignments[i]),
        worker = NA_character_
      )
    }
  }

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


#' @title Assignment Record Exists
#'
#' @param db A database connection pool
#' @param assignment The Assignment ID
#'
assignment_record_exists <- function(db, assignment) {
  query <- glue::glue_sql(
    'SELECT exists(select TRUE from eviction_addresses."assignment" where assignment_id={assignment})::int',
    .con = db
  )

  res <- DBI::dbGetQuery(db, query) |>
    dplyr::pull(exists)

  res <- as.logical(res)

  return(res)
}


#' @title New Assignment Record
#'
#' @param db A database connection pool
#' @param hit A HIT ID
#' @param assignment The Assignment ID
#' @param worker The Worker ID associated with the Assignment
#' @param status The status of the Assignment to record
#'
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
#' @param db A database connection pool
#' @param assignment The ID of the Assignment to create a db record for
#' @param status The status to record for the Assignment
#' @param answer The Assignment answer to record. Default is `NULL`
#' @param attempt A logical indicating whether this update is the result of a review attempt
#'
update_assignment_record <- function(db, assignment, status, answer = NULL, attempt = F) {
  assert_that(
    is.string(assignment),
    is.string(status),
    stringr::str_to_title(status) %in% valid_assignment_statuses
  )

  assignment_table <- DBI::Id(schema = "eviction_addresses", table = "assignment")

  status <- stringr::str_to_lower(status)

  q <- 'UPDATE eviction_addresses."assignment" SET status = {status}'

  if (isTRUE(attempt)) {
    q <- stringr::str_c(q, "attempts = attempts + 1", sep = ", ")
  }

  if (!is.null(answer)) {
    ## Insert answer argument checks
    json_answer <- jsonlite::toJSON(answer)

    q <- stringr::str_c(q, "answer = {json_answer}", sep = ", ")
  }

  q <- stringr::str_c(q, "WHERE assignment_id = {assignment};", sep = " ")

  query <- glue::glue_sql(
    q,
    .con = db
  )

  res <- DBI::dbExecute(db, query)

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
    has_names(address, c("line1", "city", "state", "zip"))
  )

  if (!has_names(address, "line2")) {
    address$line2 <- ""
  }

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

  answer <- assignment_details$Answers |>
    parse_assignment_answer()

  return(answer)
}


#' @title Review Assignment
#'
#' @param db A database connection pool
#' @param config The path to a config file
#' @param assignment The Assignment id. A string (character vector length one)
#'
#' @return If successful, True
#'
review_assignment <- function(db, config, assignment) {
  assignment_status <- get_assignment_status(assignment = assignment)
  if (assignment_status == "submitted") {
    answer <- get_assignment_answer(assignment = assignment)
    log_debug("Answer: {answer}")
    res <- tryCatch(
      send_postgrid_request(config = config, address = answer, geocode = T),
      error = function(err) {
        log_error("{Failed Postgres response: err$message}")
      }
    )

    if (inherits(res, "error")) {
      update_assignment_record(
        db = db,
        assignment = assignment,
        status = "rejected",
        attempt = T
      )

      pyMTurkR::RejectAssignment(assignments = assignment)
    } else {
      log_debug("Successful Postgrid response: {res}")
      update_assignment_record(
        db = db,
        assignment = assignment,
        status = "approved",
        answer = res,
        attempt = T
      )

      pyMTurkR::ApproveAssignment(assignments = assignment)
    }
  }
}


#' @title Compare HIT Assignments
#'
#' @param db A database connection pool
#' @param hit The HIT id for which to compare all assignments
#'
#' @return Nothing
#'
#' @import assertthat
#'
#' @examples
#' \dontrun{
#' compare_hit_assignments(hit = "<insert hit id>")
#' }
#'
compare_hit_assignments <- function(db, hit) {

  query <- glue::glue_sql(
    'SELECT "answer" FROM "eviction_addresses"."assignment" WHERE "hit"={hit};',
    .con = db
  )

  res <- DBI::dbGetQuery(db, query)

  assert_that(
    is.data.frame(res)
    !is.na(nrow(res))
  )

  if (nrow(res) >= 2) {
    log_debug("{nrow(res)} reviewed answers found. Comparing answers for HIT: {hit}")
  } else {
    log_debug("Only {nrow(res)} reviewed answers found for HIT: {hit}")
    return()
  }


}


#' @title Review HIT Assignments
#'
#' @param db A database connection pool
#' @param config The path to a config file
#' @param hit The HIT id
#'
review_hit_assignments <- function(db, config, hit) {
  assignments <- get_hit_assignments(db = db, hit = hit)

  for (i in 1:seq_along(assignments)) {
    if (!assignment_record_exists(db, assignments[i])) {
      new_assignment_record(
        db = db,
        hit = hit,
        assignment = assignments[1],
        worker = NA,
        status = get_assignment_status(assignments[1])
      )
    }

    r <- tryCatch(
      review_assignment(db = db, config = config, assignment = assignments[i]),
      error = function(err) {
        log_debug("{err$message}")
      }
    )
  }
}


# #' @title Sync Assignments
# #'
# sync_assignments <- function(db) {
#   assignment_table <- DBI::Id(schema = "eviction_addresses", table = "assignment")
#
#
# }
