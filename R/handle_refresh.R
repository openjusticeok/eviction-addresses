#' @title Handle API Refresh
#' @description Plumber handler for endpoint /refresh
#'
#' @details
#' This endpoint refreshes materialized views and inserts new cases and
#' documents into the eviction_addresses schema. It then updates the work queue
#' based on what it finds.
#'
#' @return A 200 if successful
#' @export
#'
#' @import logger
#' @import DBI
#' @import promises
#'
handle_refresh <- function(connection_args) {
  f <- function(res) {
    future_promise({
      log_appender(appender_tee("test.log"))

      db <- new_db_connection(connection_args)
      on.exit(pool::poolClose(db))

      ## Refresh both materialized views to ingest new eviction cases and minutes
      refresh_cases_query <- "REFRESH MATERIALIZED VIEW eviction_addresses.recent_tulsa_evictions;"
      refresh_minutes_query <- "REFRESH MATERIALIZED VIEW eviction_addresses.recent_tulsa_eviction_minutes;"

      log_info("Starting case refresh")
      cases_res <- dbExecute(db, refresh_cases_query)
      log_success("Cases refreshed: {cases_res} rows affected")

      log_info("Starting minute refresh")
      minutes_res <- dbExecute(db, refresh_minutes_query)
      log_success("Minutes refreshed: {minutes_res} rows affected")

      ## Check whether there are new cases
      new_cases_query <- sql('SELECT DISTINCT(rte.id), rte.district, rte.case_type, rte.case_number, rte.date_filed, current_timestamp AS created_at, current_timestamp AS updated_at FROM eviction_addresses.recent_tulsa_evictions rte LEFT JOIN eviction_addresses."case" c ON rte.id = c.id WHERE c.id IS NULL;')
      log_info("Finding new cases")
      new_cases <- dbGetQuery(db, new_cases_query)
      num_new_cases <- nrow(new_cases)
      log_info("Found {num_new_cases} new cases")

      ## Insert new cases into case table
      if(num_new_cases >= 1) {
        dbAppendTable(
          conn = db,
          name = Id(schema = "eviction_addresses", table = "case"),
          value = new_cases
        )
        log_success("Inserted {num_new_cases} new cases to table eviction_addresses.case")
      }

      #Check whether there are new minutes
      new_minutes_query <- sql('SELECT DISTINCT(rtem.id), rtem."case", rtem.description, rtem.link, NULL AS internal_link, current_timestamp AS created_at, current_timestamp AS updated_at FROM eviction_addresses.recent_tulsa_eviction_minutes rtem LEFT JOIN eviction_addresses."document" d ON rtem.id = d.id WHERE d.id IS NULL;')
      log_info("Finding new minutes")
      new_minutes <- dbGetQuery(db, new_minutes_query)
      num_new_minutes <- nrow(new_minutes)
      log_info("Found {num_new_minutes} new minutes")

      if(num_new_minutes >= 1) {
        dbAppendTable(
          conn = db,
          name = Id(schema = "eviction_addresses", table = "document"),
          value = new_minutes
        )
        log_success("Inserted {num_new_minutes} new document minutes to table eviction_addresses.document")
      }

      ## Remove any queue rows where success is true and it's 2 weeks old
      ## ? Should we check whether the address is found in the db ?

      query <- sql("DELETE FROM eviction_addresses.queue WHERE success IS TRUE AND created_at < current_timestamp - interval '14 days';")
      num_deleted_queue_rows <- DBI::dbExecute(db, query)
      log_info("{num_deleted_queue_rows} rows deleted")


      ## Get any cases in case table without an address
      ## and having at least one document, are not in queue
      query <- sql(r"(SELECT DISTINCT(d."case"), NULL::bool AS success, NULL::bool AS working, 0::int4 AS attempts, NULL::timestamp AS started_at, NULL::timestamp AS stopped_at, current_timestamp AS created_at FROM eviction_addresses."document" d LEFT JOIN eviction_addresses.queue q ON d."case" = q."case" WHERE internal_link IS NOT NULL AND q."case" IS NULL;)")
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
    },
    seed = TRUE) |>
      then(
        function() {
          log_success("Data is up to date")
          return()
        }
      )

    msg <- "The request has been queued."
    res$status <- 200
    return(list(success = msg))
  }

  return(f)
}
