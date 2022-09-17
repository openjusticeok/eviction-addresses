#' @title Handle MTurk Batch
#'
#' @param db A database connection
#'
#' @return A handler function for `plumber::pr_handle`
#'
handle_mturk_batch <- function(db) {
  f <- function() {

    queue_length <- get_queue_length()
  }

  return(f)
}
