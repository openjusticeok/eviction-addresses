#' @title Handle MTurk Review
#'
#' @return A handler function for plumber endpoint /mturk/review
#'
handle_mturk_review <- function() {
  f <- function() {
    reviewable_hits <- get_reviewable_hits()
    for(i in seq_along(reviewable_hits)) {
      review_hit(reviewable_hits[i])
    }
  }

  return(f)
}
