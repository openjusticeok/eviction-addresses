#' @title Refresh Documents
#'
#' @param db A database connection
#'
refresh_documents <- function(db) {
  ua <- httr::user_agent(agent = "1ecbd577-793f-4a38-b82f-e361ed335168")

  logger::log_appender(logger::appender_tee("test.log"))

  googleCloudStorageR::gcs_auth(json_file = "eviction-addresses-service-account.json", email = "bq-test@ojo-database.iam.gserviceaccount.com")

  query <- dplyr::sql("SELECT id, link FROM eviction_addresses.document WHERE internal_link IS NULL ORDER BY created_at;")
  links <- DBI::dbGetQuery(db, query)

  if(nrow(links) == 0) {
    msg <- "No new documents to retrieve"
    logger::log_info(msg)
    return(list(status = "success", message = msg))
  }

  for(i in 1:nrow(links)) {
    logger::log_info("Starting link {i}")
    document <- httr::GET(links[i, "link"], ua) |>
      purrr::pluck("content")
    if(anyNA(document)) {
      logger::log_info('No pdf found at {links[i, "link"]}')
      next()
    }
    logger::log_success("Got pdf content {i}")
    upload <- googleCloudStorageR::gcs_upload(
      document,
      name = links[i, "id"],
      bucket = "eviction-addresses",
      type = "application/pdf",
      object_function = function(input, output) {
        readr::write_file(input, output)
      },
      predefinedAcl = "bucketLevel"
    )
    logger::log_success("Uploaded pdf {i}")
    internal_link <- googleCloudStorageR::gcs_download_url(
      links[i, "id"],
      bucket = "eviction-addresses",
      public = TRUE
    )
    logger::log_success("Got public link {i}")
    query <- glue::glue_sql(
      'UPDATE eviction_addresses."document" SET internal_link = {internal_link}, updated_at = current_timestamp WHERE id = {links[i, "id"]};',
      .con = db
    )
    DBI::dbExecute(db, query)

    logger::log_success("Completed link {i}/{nrow(links)}")
    Sys.sleep(2)
  }

  return()
}


#' @title Get Documents by Case
#'
#' @param db A database connection pool created with `pool::dbPool`
#' @param id The id of the case for which to return documents
#'
#' @return A data.frame of documents
#'
get_documents_by_case <- function(db, id) {
  query <- glue::glue_sql('SELECT * FROM "eviction_addresses"."document" t WHERE t."case" = {id};', .con = db)

  res <- DBI::dbGetQuery(db, query)

  return(res)
}
