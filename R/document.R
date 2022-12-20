#' @title Refresh Documents
#'
#' @param db A database connection
#' @param n The number of documents to refresh
#'
refresh_documents <- function(db, n = "ALL") {
  logger::log_appender(logger::appender_tee("test.log"))

  googleCloudStorageR::gcs_auth(
    json_file = "eviction-addresses-service-account.json",
    email = "bq-test@ojo-database.iam.gserviceaccount.com"
  )

  limit_n <- ifelse(is.numeric(n), n, "ALL")

  query <- glue::glue_sql(
    'SELECT id, link FROM "eviction_addresses"."document" t WHERE t."internal_link" IS NULL ORDER BY t."created_at" LIMIT {limit_n};',
    .con = db
  )
  links <- DBI::dbGetQuery(db, query)

  if(nrow(links) == 0) {
    msg <- "No new documents to retrieve"
    logger::log_info(msg)
    return(list(status = "success", message = msg))
  }

  for(i in seq_along(links)) {
    document <- tryCatch(
      download_oscn_document(links[i, "link"]),
      error = function(e) {
        logger::log_error("Error downloading pdf {i}: {e}")
        return(e)
      }
    )

    if(inherits(document, "error")) {
      next()
    }

    upload <- tryCatch(
      upload_gcs_document(document, links[i, "id"]),
      error = function(e) {
        logger::log_error("Error uploading pdf {i}: {e}")
        return(e)
      }
    )

    if(inherits(upload, "error")) {
      next()
    }

    link <- tryCatch(
      store_public_document_link(db, links[i, "id"]),
      error = function(e) {
        logger::log_error("Error storing public link for pdf {i}: {e}")
        return(e)
      }
    )

    if(inherits(link, "error")) {
      next()
    }

    logger::log_success("Completed link {i}/{nrow(links)}")
    Sys.sleep(2)
  }

  return()
}


#' @title Get Documents by Case
#'
#' @description Get all documents for a given case
#'
#' @param db A database connection pool created with `pool::dbPool`
#' @param id The id of the case for which to return documents
#'
#' @returns A data.frame of documents
#'
get_documents_by_case <- function(db, id) {
  query <- glue::glue_sql('SELECT * FROM "eviction_addresses"."document" t WHERE t."case" = {id};', .con = db)

  res <- DBI::dbGetQuery(db, query)

  return(res)
}


#' @title Download OSCN Document
#'
#' @description Download a document from OSCN
#'
#' @param link The link to the document
#'
#' @export
#' @returns A pdf document as a raw vector
#'
download_oscn_document <- function(link) {
  logger::log_debug("Getting pdf from OSCN: {link}")
  ua <- httr::user_agent(agent = "1ecbd577-793f-4a38-b82f-e361ed335168")
  res <- httr::GET(
    link,
    ua
  )

  if(!res$status_code == 200) {
    logger::log_error("Bad response from link: {link}")
    rlang::abort("Bad http response from {link}")
  }

  if(!res$headers$`content-type` == "application/pdf") {
    logger::log_error("Bad content type from link: {link}")
    rlang::abort("Bad content type from {link}")
  }

  doc <- httr::content(res, "raw")

  expected_size <- as.integer(res$headers$`content-length`)
  actual_size <- length(doc)

  if(!expected_size == actual_size) {
    logger::log_error("Captured response is size {actual_size}. Expected {expected_size}")
    rlang::abort("Content was corrupted during download")
  }

  logger::log_debug("Got pdf from OSCN: {link}")

  return(doc)
}

#' @title Upload GCS Document
#'
#' @description Upload a document to Google Cloud Storage
#'
#' @param file A pdf document as a raw vector
#' @param id The id/name of the document
#'
upload_gcs_document <- function(file, id) {
  gcs_upload_set_limit(upload_limit = 10000000L)
  logger::log_debug("Uploading pdf to GCS: {id}")
  upload <- googleCloudStorageR::gcs_upload(
    file = file,
    name = id,
    bucket = "eviction-addresses",
    type = "application/pdf",
    object_function = function(input, output) {
      readr::write_file(
        x = input,
        file = output,
        append = FALSE
      )
    },
    predefinedAcl = "bucketLevel",
    upload_type = "simple"
  )
  logger::log_debug("Uploaded pdf to GCS: {upload}")

  return(upload)
}

#' @title Store Public Document Link
#'
#' @description Store the GCS link to a document in the database
#'
#' @param db A database connection pool created with `pool::dbPool`
#' @param id The id of the document
#'
store_public_document_link <- function(db, id) {
  logger::log_debug("Storing GCS link for pdf {id}")
  internal_link <- googleCloudStorageR::gcs_download_url(
    object_name = id,
    bucket = "eviction-addresses",
    public = TRUE
  )
  logger::log_success("Got public link for pdf: {internal_link}")

  query <- glue::glue_sql(
    'UPDATE eviction_addresses."document" SET internal_link = {internal_link}, updated_at = current_timestamp WHERE id = {id};',
    .con = db
  )
  DBI::dbExecute(db, query)
  logger::log_success("Updated document {id} with internal link {internal_link}")

  return()
}
