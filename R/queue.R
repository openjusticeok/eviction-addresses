#' @title Get Queue Length
#'
#' @param db A database connection pool
#' @param status A character string indicating whether to count all cases in the queue or only those that are available for processing. Defaults to "available".
#'
#' @returns The length of the queue. An integer.
#'
#' @import assertthat
#' @importFrom rlang .data
#'
get_queue_length <- function(db, status = "available") {
  queue_table <- dbplyr::in_schema(schema = "eviction_addresses", table = "queue")
  queue <- dplyr::tbl(db, queue_table)

  status <- rlang::arg_match(status, c("available", "all"))
  if(status == "available") {
    queue <- queue |>
      dplyr::filter(
        is.na(.data$success),
        is.na(.data$working)
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


#' @title Clean Queue
#'
#' @description
#' Removes completed cases from the queue and handles abandoned cases
#'
#' @param db A database connection
#'
#'
clean_queue <- function(db) {
  ## Remove any queue rows where success is true and it's 2 weeks old
  ## ? Should we check whether the address is found in the db ?

  query <- dbplyr::sql("DELETE FROM eviction_addresses.queue WHERE success IS TRUE AND created_at < current_timestamp - interval '14 days';")
  num_deleted_queue_rows <- DBI::dbExecute(db, query)
  logger::log_info("{num_deleted_queue_rows} rows deleted")

  return()
}


#' @title Update Queue
#'
#' @description
#' Finds and adds new cases to queue based on a case's lack of an address and presence of one or more documents
#'
#' @param db A database connection
#'
#'
update_queue <- function(db) {
  ## Get any cases in case table without an address
  ## and having at least one document, are not in queue
  query <- dbplyr::sql(r"(SELECT DISTINCT(d."case"), NULL::bool AS success, NULL::bool AS working, 0::int4 AS attempts, NULL::timestamp AS started_at, NULL::timestamp AS stopped_at, current_timestamp AS created_at FROM eviction_addresses."document" d LEFT JOIN eviction_addresses.queue q ON d."case" = q."case" left join eviction_addresses.address a on d."case" = a."case" WHERE internal_link IS NOT NULL AND q."case" IS null and a."case" is null;)")
  new_jobs <- DBI::dbGetQuery(db, query)

  num_new_jobs <- nrow(new_jobs)
  logger::log_info("{num_new_jobs} new jobs found")

  if(num_new_jobs >= 1) {
    DBI::dbAppendTable(
      conn = db,
      name = DBI::Id(schema = "eviction_addresses", table = "queue"),
      value = new_jobs
    )
    logger::log_success("Inserted {num_new_jobs} new jobs to queue")
  } else {
    logger::log_info("No new jobs to add")
  }

  return()
}


#' @title Refresh Queue
#'
#' @param db A database connection
#'
refresh_queue <- function(db) {
  clean_queue(db)
  update_queue(db)

  return()
}


#' @title Get Case from Queue
#'
#' @param db A database connection pool created with `pool::dbPool`
#'
#' @returns A case id
#'
get_case_from_queue <- function(db) {
  pool::poolWithTransaction(db, func = function(conn) {
    case <- DBI::dbGetQuery(
      conn,
      dbplyr::sql('SELECT q."case" FROM eviction_addresses.queue q LEFT JOIN eviction_addresses."case" c ON q."case" = c."id" LEFT JOIN public."case" pc ON q."case" = pc.id WHERE "success" IS NOT TRUE AND "working" IS NOT TRUE ORDER BY attempts ASC, pc.status DESC, c.date_filed DESC LIMIT 1 FOR UPDATE OF q SKIP LOCKED;')
    )
    query <- glue::glue_sql(
      'UPDATE "eviction_addresses"."queue" SET working = TRUE, started_at = CURRENT_TIMESTAMP, stopped_at = NULL WHERE "case" = {case}',
      .con = conn
    )
    res <- DBI::dbExecute(conn, query)

    case_id <- case$case[1]

    return(case_id)
  })
}
