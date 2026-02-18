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
  ## Remove any queue rows where success is true

  query <- dbplyr::sql("DELETE FROM eviction_addresses.queue WHERE success IS TRUE;")
  num_deleted_queue_rows <- DBI::dbExecute(db, query)
  logger::log_info("{num_deleted_queue_rows} completed rows deleted from queue")

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
  logger::log_debug("Getting new jobs")
  query <- dbplyr::sql(r"(SELECT DISTINCT(d."case"), NULL::bool AS success, NULL::bool AS working, 0::int4 AS attempts, NULL::timestamp AS started_at, NULL::timestamp AS stopped_at, current_timestamp AS created_at FROM eviction_addresses."document" d LEFT JOIN eviction_addresses.queue q ON d."case" = q."case" left join eviction_addresses.address a on d."case" = a."case" WHERE internal_link IS NOT NULL AND q."case" IS null and a."case" is null;)")
  new_jobs <- DBI::dbGetQuery(db, query)

  num_new_jobs <- nrow(new_jobs)
  logger::log_debug("{num_new_jobs} new jobs found")

  if(num_new_jobs >= 1) {
    DBI::dbAppendTable(
      conn = db,
      name = DBI::Id(schema = "eviction_addresses", table = "queue"),
      value = new_jobs
    )
    logger::log_debug("Inserted {num_new_jobs} new jobs to table eviction_addresses.queue")
  } else {
    logger::log_debug("No new jobs to add")
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


#' @title Reset Stuck Queue Items
#'
#' @description
#' Resets queue items that have been stuck in 'working' status for over an hour.
#' These are typically cases from crashed or abandoned sessions.
#' Items that exceed max retry attempts (3) are logged but not reset.
#'
#' @param db A database connection
#' @param max_retries Maximum number of retry attempts before giving up on a case. Defaults to 3.
#' @param stale_threshold_hours Number of hours before a working case is considered stuck. Defaults to 1.
#'
#' @returns Nothing
#'
reset_stuck_queue_items <- function(db, max_retries = 3, stale_threshold_hours = 1) {
  # Find stuck cases: working=TRUE and started over threshold hours ago
  stuck_query <- glue::glue_sql(.con = db, "
    SELECT \"case\", attempts 
    FROM eviction_addresses.queue 
    WHERE working = TRUE 
      AND started_at < CURRENT_TIMESTAMP - INTERVAL '{stale_threshold_hours} hours';
  ")
  
  stuck_cases <- DBI::dbGetQuery(db, stuck_query)
  
  if (nrow(stuck_cases) == 0) {
    logger::log_info("No stuck queue items found")
    return(invisible(NULL))
  }
  
  num_stuck <- nrow(stuck_cases)
  num_max_retries <- sum(stuck_cases$attempts >= max_retries)
  num_to_reset <- num_stuck - num_max_retries
  
  # Reset cases that haven't exceeded max retries
  if (num_to_reset > 0) {
    reset_query <- glue::glue_sql(.con = db, "
      UPDATE eviction_addresses.queue 
      SET working = FALSE, 
          attempts = attempts + 1, 
          stopped_at = CURRENT_TIMESTAMP 
      WHERE working = TRUE 
        AND started_at < CURRENT_TIMESTAMP - INTERVAL '{stale_threshold_hours} hours'
        AND attempts < {max_retries};
    ")
    
    num_reset <- DBI::dbExecute(db, reset_query)
    logger::log_info("Reset {num_reset} stuck queue items (out of {num_stuck} total stuck)")
  }
  
  # Log cases that hit max retries
  if (num_max_retries > 0) {
    logger::log_warn("{num_max_retries} queue items reached max retry limit ({max_retries}) and will not be reset")
  }
  
  return(invisible(NULL))
}
