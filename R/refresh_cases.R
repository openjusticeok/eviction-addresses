#' @title Refresh Cases
#'
#' @param db A database connection
#'
#' @export
#'
refresh_cases <- function(db) {
  refresh_cases_query <- "REFRESH MATERIALIZED VIEW eviction_addresses.recent_tulsa_evictions;"

  log_info("Starting case refresh")
  cases_res <- dbExecute(db, refresh_cases_query)
  log_success("Cases refreshed: {cases_res} rows affected")

  ## Check whether there are new cases
  new_cases_query <- dbplyr::sql('SELECT DISTINCT(rte.id), rte.district, rte.case_type, rte.case_number, rte.date_filed, current_timestamp AS created_at, current_timestamp AS updated_at FROM eviction_addresses.recent_tulsa_evictions rte LEFT JOIN eviction_addresses."case" c ON rte.id = c.id WHERE c.id IS NULL;')
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

  return()
}
