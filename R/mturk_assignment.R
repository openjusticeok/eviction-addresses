valid_assignment_statuses <- c("Submitted", "Approved", "Rejected")


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

  assert_that(
    is.list(address),
    has_names(address, c("line1", "line2", "city", "state", "zip"))
  )

  address <- list(
    line1 = address$line1,
    line2 = address$line2,
    city = address$city,
    provinceOrState = address$state,
    zip = address$zip,
    country = "us"
  )

  return(address)
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


#' @title Review HIT Assignments
#' 
#' @param hit The HIT id
review_hit_assignments <- function(hit) {
  assignments <- get_hit_assignments(hit)

  for(i in 1:seq_along(assignments)) {
    res <- review_assignment(assignments[i])
    if(res) {

    }
  }

  res <- compare_hit_assignments(hit)

  return()
}
