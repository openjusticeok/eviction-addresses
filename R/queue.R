#' @title Get Queue Length
#'
#' @param db A database connection pool
#'
#' @return The length of the queue. An integer.
#' @export
#'
get_queue_length <- function(db, status = "available") {
  queue_table <- dbplyr::in_schema(schema = "eviction_addresses", table = "queue")
  queue <- dplyr::tbl(db, queue_table)

  status <- rlang::arg_match(status, c("available", "all"))
  if(status == "available") {
    queue <- queue |>
      dplyr::filter(
        is.na(success),
        is.na(working)
      )
  }

  queue_length <- queue |>
    dplyr::count() |>
    dplyr::collect() |>
    dplyr::pull() |>
    as.integer()

  assert_that(
    is.integer(queue_length)
  )

  return(queue_length)
}
