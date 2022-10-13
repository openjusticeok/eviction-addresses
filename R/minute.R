#' @title Refresh Minutes
#'
#' @param db A database connection
#'
refresh_minutes <- function(db) {
  refresh_minutes_query <- "REFRESH MATERIALIZED VIEW eviction_addresses.recent_tulsa_eviction_minutes;"

  logger::log_info("Starting minute refresh")
  minutes_res <- DBI::dbExecute(db, refresh_minutes_query)
  logger::log_success("Minutes refreshed: {minutes_res} rows affected")

  #Check whether there are new minutes
  new_minutes_query <- dbplyr::sql('SELECT DISTINCT(rtem.id), rtem."case", rtem.description, rtem.link, NULL AS internal_link, current_timestamp AS created_at, current_timestamp AS updated_at FROM eviction_addresses.recent_tulsa_eviction_minutes rtem LEFT JOIN eviction_addresses."document" d ON rtem.id = d.id WHERE d.id IS NULL;')
  logger::log_info("Finding new minutes")
  new_minutes <- DBI::dbGetQuery(db, new_minutes_query)
  num_new_minutes <- nrow(new_minutes)
  logger::log_info("Found {num_new_minutes} new minutes")

  if(num_new_minutes >= 1) {
    DBI::dbAppendTable(
      conn = db,
      name = DBI::Id(schema = "eviction_addresses", table = "document"),
      value = new_minutes
    )
    logger::log_success("Inserted {num_new_minutes} new document minutes to table eviction_addresses.document")
  }

  return()
}
