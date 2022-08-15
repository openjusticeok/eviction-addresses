#' @title Handle Hydrate
#' @description A plumber handler for the /hydrate endpoint
#'
#' @details
#' This endpoint searches eviction document minutes for links. It downloads the
#' documents, stores them in a Google Cloud bucket, then creates an internal
#' link to the document.
#'
#' @return A 200, if successful
#' @export
#'
handle_hydrate <- function() {
  promises::future_promise({

    log_appender(appender_tee("test.log"))

    googleCloudStorageR::gcs_auth(json_file = "eviction-addresses-service-account.json", email = "bq-test@ojo-database.iam.gserviceaccount.com")

    ojodb <- create_pool(connection_args)
    on.exit(pool::poolClose(ojodb))

    query <- sql("SELECT id, link FROM eviction_addresses.document WHERE internal_link IS NULL ORDER BY created_at;")
    links <- DBI::dbGetQuery(ojodb, query)

    if(nrow(links) == 0) {
      msg <- "No new documents to retrieve"
      log_info(msg)
      return(list(status = "success", message = msg))
    }

    for(i in 1:nrow(links)) {
      log_info("Starting link {i}")
      document <- GET(links[i, "link"]) |>
        pluck(content)
      if(anyNA(document)) {
        log_info('No pdf found at {links[i, "link"]}')
        next()
      }
      log_success("Got pdf content {i}")
      upload <- gcs_upload(document,
                           name = links[i, "id"],
                           bucket = "eviction-addresses",
                           type = "application/pdf",
                           object_function = function(input, output) {
                             write_file(input, output)
                           },
                           predefinedAcl = "bucketLevel")
      log_success("Uploaded pdf {i}")
      internal_link <- gcs_download_url(links[i, "id"],
                                        bucket = "eviction-addresses",
                                        public = T)
      log_success("Got public link {i}")
      query <- glue_sql('UPDATE eviction_addresses."document" SET internal_link = {internal_link}, updated_at = current_timestamp WHERE id = {links[i, "id"]};',
                        .con = ojodb)
      DBI::dbExecute(ojodb, query)

      log_success("Completed link {i}/{nrow(links)}")
      Sys.sleep(2)
    }

    return()
  },
  seed = TRUE) |>
    then(
      function() {
        log_success("Fully hydrated")
        return()
      }
    )

  return()
}
