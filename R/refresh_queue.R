#' @title Refresh Queue
#'
#' @param db A database connection
#'
#' @export
#'
refresh_queue <- function(db) {
  ## Remove any queue rows where success is true and it's 2 weeks old
  ## ? Should we check whether the address is found in the db ?

  query <- dbplyr::sql("DELETE FROM eviction_addresses.queue WHERE success IS TRUE AND created_at < current_timestamp - interval '14 days';")
  num_deleted_queue_rows <- DBI::dbExecute(db, query)
  log_info("{num_deleted_queue_rows} rows deleted")


  ## Get any cases in case table without an address
  ## and having at least one document, are not in queue
  query <- dbplyr::sql(r"(SELECT DISTINCT(d."case"), NULL::bool AS success, NULL::bool AS working, 0::int4 AS attempts, NULL::timestamp AS started_at, NULL::timestamp AS stopped_at, current_timestamp AS created_at FROM eviction_addresses."document" d LEFT JOIN eviction_addresses.queue q ON d."case" = q."case" WHERE internal_link IS NOT NULL AND q."case" IS NULL;)")
  new_jobs <- dbGetQuery(db, query)

  num_new_jobs <- nrow(new_jobs)

  if(num_new_jobs >= 1) {
    dbAppendTable(
      conn = db,
      name = Id(schema = "eviction_addresses", table = "queue"),
      value = new_jobs
    )
    log_success("Inserted {num_new_jobs} new jobs to table eviction_addresses.queue")
  } else {
    log_info("No new jobs to add")
  }

  return()
}
