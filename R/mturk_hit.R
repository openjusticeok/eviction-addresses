valid_hit_statuses <- c("Assignable", "Unassignable", "Reviewable", "Reviewing", "Disposed")
#valid_hit_review_statuses <- c("NotReviewed", "MarkedForReview", "ReviewedAppropriate", "ReviewedInappropriate")


#' @title New Sample HIT
#'
#' @param db A database connection pool
#'
#' @return The HIT id. A string (character vector length one)
#'
#' @import assertthat
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
#' @param db A database connection pool
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
#' @return The HIT status. A string (character vector of length one).
#' See `valid_hit_statuses` for possible values.
#'
#' @import assertthat
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
#' @param db A database connection pool
#' @param config A configuration file
#' @param hit The HIT id. A string (character vector length one)
#'
review_hit <- function(db, config, hit) {

  hit_status <- get_hit_status(db, hit)

  if(hit_status == "reviewable") {
    tryCatch(
      review_hit_assignments(db = db, config = config, hit = hit),
      error = function(err) {
        logger::log_error(err)
      }
    )

    tryCatch(
      compare_hit_assignments(db = db, hit = hit),
      error = function(err) {
        logger::log_error(err)
      }
    )
  }

  return()
}


#' @title Dispose HIT
#'
#' @param db A database connection pool
#' @param hit The HIT id to dispose
#'
#' @return Nothing
#'
#' @import assertthat
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
#' @param db A database connection pool
#'
#' @return A set of reviewable HITs
#'
#' @import assertthat
#'
get_reviewable_hits <- function(db) {
  query <- glue::glue_sql("SELECT hit_id FROM eviction_addresses.hit WHERE status = 'reviewable'", .con = db)

  res <- DBI::dbGetQuery(db, query)
  reviewable_hits <- res$hit_id

  return(reviewable_hits)
}


#' @title New HIT Record
#'
#' @param db A database connection pool
#' @param hit The HIT ID to record
#' @param case The case id associated with the HIT
#'
#' @return NULL
#'
#' @import assertthat
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
#' @import assertthat
#'
update_hit_record <- function(db, hit, status) {
  assert_that(
    is.string(hit),
    is.string(status),
    stringr::str_to_title(status) %in% valid_hit_statuses
  )

  status <- stringr::str_to_lower(status)

  query <- glue::glue_sql(
    'UPDATE eviction_addresses."hit" SET status = {status} WHERE hit_id = {hit};',
    .con = db
  )

  tryCatch(
    expr = DBI::dbExecute(db, query),
    error = function(err) {
      rlang::abort("Could not complete query")
    }
  )

  return()
}

#' @title Sync HITs in database with MTurk
#'
#' @param db A database connection pool
#'
sync_hits <- function(db) {
  hit_table <- DBI::Id(schema = "eviction_addresses", table = "hit")
  h <- dplyr::tbl(db, hit_table) |>
    dplyr::filter(status != "disposed") |>
    dplyr::pull(hit_id)

  if(length(h) == 0) {
    return()
  }

  for(i in seq_along(h)) {
    tryCatch(
      {
        s <- get_hit_status(db, h[i])
        update_hit_record(db, h[i], s)
      },
      error = function(err) {
        logger::log_error("Could not synchronize HIT {h[i]}: {err}")
      }
    )
  }
}
