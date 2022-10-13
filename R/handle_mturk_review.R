#' @title Handle MTurk Review
#'
#' @return A handler function for plumber endpoint /mturk/review
#'
handle_mturk_review <- function(db, config) {
  f <- function() {
    sync_hits(db)

    reviewable_hits <- get_reviewable_hits(db = db)
    logger::log_debug("{length(reviewable_hits)} reviewable hits found")

    for(i in seq_along(reviewable_hits)) {
      res <- tryCatch(
        review_hit(db = db, config = config, hit = reviewable_hits[i]),
        error = function(err) {
          err
        }
      )

      if(inherits(res, "error")) {
        logger::log_error(res$message)
        next()
      }
    }

    return()
  }

  return(f)
}
