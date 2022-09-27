#' @title Handle MTurk Batch
#'
#' @param db A database connection
#'
#' @return A handler function for `plumber::pr_handle`
#'
handle_mturk_batch <- function(db, max_batch_size) {
  assert_that(
    is.number(max_batch_size),
    is.integer(max_batch_size)
  )

  f <- function(max_batch_size) {
    new_mturk_batch(db, max_batch_size, hit_type)
  }

  return(f)
}
