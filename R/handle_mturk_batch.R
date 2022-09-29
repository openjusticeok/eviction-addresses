#' @title Handle MTurk Batch
#'
#' @param db A database connection
#' @param max_batch_size Maximum number of MTurk HITs to create at once
#'
#' @return A handler function for `plumber::pr_handle`
#'
handle_mturk_batch <- function(db, max_batch_size) {
  assert_that(
    is.count(max_batch_size)
  )

  ht <- new_hit_type()

  f <- function() {
    new_mturk_batch(
      db = db,
      max_batch_size = max_batch_size,
      hit_type = ht
    )
  }

  return(f)
}
