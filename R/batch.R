#' @title New MTurk Batch
#'
#' @param db
#' @param max_batch_size
#'
#' @return
#' @export
#'
#' @examples
new_mturk_batch <- function(db, max_batch_size) {
  assert_that(
    is.number(max_batch_size),
    is.integer(max_batch_size)
  )

  queue_length <- get_queue_length(db)
  if(queue_length > 0) {
    up_limit <- min(queue_length, max_batch_size)
    for(i in 1:up_limit) {
      c <- new_case_from_queue(db)
      new_hit_from_case(db, c)
    }
  }
}


