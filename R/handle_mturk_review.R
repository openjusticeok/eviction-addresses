#' @title Handle MTurk Review
#'
#' @return A handler function for plumber endpoint /mturk/review
#'
handle_mturk_review <- function(db, config) {
  f <- function() {
    reviewable_hits <- get_reviewable_hits()
    for(i in seq_along(reviewable_hits)) {
      tryCatch(
        review_hit(db = db, config = config, hit = reviewable_hits[i]),
        error = function(err) {

        }
      )
    }

    return()
  }

  return(f)
}
