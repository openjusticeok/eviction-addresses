#' @title Handle Hydrate
#' @description A plumber handler for the /hydrate endpoint
#'
#' @details
#' This endpoint searches eviction document minutes for links. It downloads the
#' documents, stores them in a Google Cloud bucket, then creates an internal
#' link to the document.
#'
#'
#' @return A 200, if successful
#' @export
#'
handle_hydrate <- function() {

  f <- function(res) {
    ua <- httr::user_agent(agent = "1ecbd577-793f-4a38-b82f-e361ed335168")

    promises::future_promise({

      logger::log_appender(appender_tee("test.log"))

      googleCloudStorageR::gcs_auth(json_file = "eviction-addresses-service-account.json", email = "bq-test@ojo-database.iam.gserviceaccount.com")

      ojodb <- new_db_connection()
      on.exit(pool::poolClose(ojodb))

      query <- dplyr::sql("SELECT id, link FROM eviction_addresses.document WHERE internal_link IS NULL ORDER BY created_at;")
      links <- DBI::dbGetQuery(ojodb, query)

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
        upload <- googleCloudStorageR::gcs_upload(document,
                                                  name = links[i, "id"],
                                                  bucket = "eviction-addresses",
                                                  type = "application/pdf",
                                                  object_function = function(input, output) {
                                                    readr::write_file(input, output)
                                                  },
                                                  predefinedAcl = "bucketLevel")
        logger::log_success("Uploaded pdf {i}")
        internal_link <- googleCloudStorageR::gcs_download_url(links[i, "id"],
                                                               bucket = "eviction-addresses",
                                                               public = T)
        logger::log_success("Got public link {i}")
        query <- glue::glue_sql('UPDATE eviction_addresses."document" SET internal_link = {internal_link}, updated_at = current_timestamp WHERE id = {links[i, "id"]};',
                                .con = ojodb)
        DBI::dbExecute(ojodb, query)

        logger::log_success("Completed link {i}/{nrow(links)}")
        Sys.sleep(2)
      }

      return()
    },
    seed = TRUE) |>
      then(
        function() {
          logger::log_success("Fully hydrated")
          return()
        }
      )

    return()
  }

  return(f)
}
