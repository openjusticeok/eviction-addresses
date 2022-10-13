#' @title New MTurk Batch
#'
#' @param db A database connection pool
#' @param max_batch_size The maximum number of HITs to create at once
#' @param hit_type The HIT Type to use for created HITs
#'
#' @return Empty
#'
#' @import assertthat
#'
new_mturk_batch <- function(db, max_batch_size, hit_type) {
  assert_that(
    is.count(max_batch_size),
    is.string(hit_type)
  )

  queue_length <- get_queue_length(db)
  if(queue_length > 0) {
    up_limit <- min(queue_length, max_batch_size)
    for(i in seq_len(up_limit)) {
      tryCatch(
        batch_case(db, hit_type),
        error = function(err) {
          ## insert error handling
          logger::log_error(err)
        }
      )
    }
  }

  return()
}

#' Batch a Case
#'
#' @param db A database connection pool
#' @param hit_type The HIT Type ID to use for this batch
#'
batch_case <- function(db, hit_type) {
  c <- new_case_from_queue(db)

  h <- new_hit_from_case(
    db = db,
    case = c,
    hit_type = hit_type
  )

  return(h)
}
