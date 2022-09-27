valid_hit_statuses <- c("Assignable", "Unassignable", "Reviewable", "Reviewing", "Disposed")
valid_hit_review_statuses <- c("NotReviewed", "MarkedForReview", "ReviewedAppropriate", "ReviewedInappropriate")


#' @title New Sample HIT
#'
#' @return The HIT id. A string (character vector length one)
#'
new_sample_hit <- function(db) {
  links <- c("https://google.com", "https://twitter.com")

  hit_type <- new_hit_type()

  hit_layout <- render_hit_layout(links = links)
  mturk_question <- pyMTurkR::GenerateHTMLQuestion(character = hit_layout)

  hit <- pyMTurkR::CreateHITWithHITType(
    hit.type = hit_type,
    question = mturk_question,
    expiration = pyMTurkR::seconds(days = 1),
    assignments = "3",
    unique.request.token = uuid::UUIDgenerate(output = "string")
  )

  assert_that(
    has_names(hit, c("HITId", "Valid")),
    is.string(hit$HITId),
    isTRUE(as.logical(hit$Valid))
  )

  new_hit_record(
    db = db,
    hit = hit$HITId,
    case = ""
  )

  return(hit$HITId)
}


#' @title New Hit from Case
#'
#' @param case The case id from which to create a new HIT
#' @param hit_type The HIT Type id from which to create a new HIT
#'
#' @return A HIT
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

  hit_layout <- render_hit_layout_for_case(db, case)
  mturk_question <- pyMTurkR::GenerateHTMLQuestion(character = hit_layout)

  hit <- pyMTurkR::CreateHITWithHITType(
    hit.type = hit_type,
    question = mturk_question,
    expiration = pyMTurkR::seconds(days = 1),
    assignments = "3",
    unique.request.token = uuid::UUIDgenerate(output = "string")
  )

  assert_that(
    has_names(hit, c("HITId", "Valid")),
    is.string(hit$HITId),
    isTRUE(as.logical(hit$Valid))
  )

  new_hit_record(
    db = db,
    hit = hit$HITId,
    case = case
  )

  return(hit$HITId)
}


#' @title Get HIT Status
#'
#' @param db A database connection
#' @param hit The hit id. A string (character vector of length one)
#'
#' @return The HIT status. A string (character vector of length one). See `valid_hit_statuses` for possible values.
#'
get_hit_status <- function(db, hit) {
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

  update_hit_record(
    db = db,
    hit = hit,
    status = tolower(hit_status)
  )

  return(tolower(hit_status))
}


#' @title Review HIT
#'
#' @param hit The HIT id. A string (character vector length one)
#'
#' @return ??
#'
review_hit <- function(db, hit) {

  hit_status <- get_hit_status(db, hit)
  if(hit_status == "reviewable") {
    res <- review_hit_assignments(hit)
  }
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
#' dispose_hit(db, hit = "<insert hit id>")
#'
dispose_hit <- function(db, hit = NULL) {
  assert_that(
    is.string(hit)
  )

  res <- pyMTurkR::DeleteHIT(
    hit = hit,
    approve.pending.assignments = F,
    skip.delete.prompt = T
  )

  assert_that(
    is.data.frame(res),
    has_names(res, c("HITId", "Valid")),
    isTRUE(as.logical(res$Valid))
  )

  update_hit_record(
    db = db,
    hit = hit,
    status = "disposed"
  )

  return()
}


#' @title Get Reviewable HITs
#'
#' @return A set of reviewable HITs
#'
get_reviewable_hits <- function() {
  reviewable_hits <- pyMTurkR::GetReviewableHITs()

  return(reviewable_hits)
}


#' @title New HIT Record
#'
#' @param db
#' @param hit
#' @param case
#'
#' @return NULL
#'
new_hit_record <- function(db, hit, case) {
  assert_that(
    is.string(hit)
  )

  hit_table <- DBI::Id(schema = "eviction_addresses", table = "hit")

  h <- data.frame(
    hit_id = hit,
    case = case,
    status = "assignable",
    created_at = lubridate::now()
  )

  DBI::dbAppendTable(
    conn = db,
    name = hit_table,
    value = h
  )

  return()
}


#' @title Update HIT Record
#'
#' @param db A database connection
#' @param hit A HIT id; a string
#' @param status A HIT Status; a string
#'
#' @return
#'
update_hit_record <- function(db, hit, status) {
  assert_that(
    is.string(hit),
    is.string(status),
    stringr::str_to_title(status) %in% valid_hit_statuses
  )

  hit_table <- DBI::Id(schema = "eviction_addresses", table = "hit")

  status <- stringr::str_to_lower(status)

  query <- glue::glue_sql('UPDATE eviction_addresses."hit" SET status = {status} WHERE hit_id = {hit};',
                          .con = db)

  res <- DBI::dbExecute(db, query)

  assert_that(
    is.count(res)
  )

  return()
}
