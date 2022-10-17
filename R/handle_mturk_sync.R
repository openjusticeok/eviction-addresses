#' @title Handle MTurk Sync
#'
#' @return A handler function for plumber endpoint /mturk/sync
#'
handle_mturk_sync <- function(db) {
  f <- function() {
    sync_hits(db)

    return()
  }

  return(f)
}
