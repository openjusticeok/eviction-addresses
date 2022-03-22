library(plumber)
library(tidyverse)
library(future)
library(promises)
library(DBI)
library(rusps)
library(XML)
library(ggmap)
library(httr)
library(ojodb)
library(bigrquery)
library(googleCloudRunner)
library(googleCloudStorageR)
library(cli)
library(here)
library(config)
library(odbc)
library(dbplyr)

options(gargle_verbosity = "debug")
plan(multisession)
googleCloudStorageR::gcs_auth(json_file = "eviction-addresses-service-account.json", email = "bq-test@ojo-database.iam.gserviceaccount.com")



if(Sys.getenv("PORT") == "") Sys.setenv(PORT = 8000)


connection_args <- config::get('database')

ojodb <- pool::dbPool(odbc::odbc(),
                      Driver = connection_args$driver,
                      Server = connection_args$server,
                      Database = connection_args$database,
                      Port = connection_args$port,
                      Username = connection_args$uid,
                      Password = connection_args$pwd,
                      SSLmode = "verify-ca",
                      Pqopt = stringr::str_glue(
                        "{sslrootcert={{connection_args$ssl.ca}}",
                        "sslcert={{connection_args$ssl.cert}}",
                        "sslkey={{connection_args$ssl.key}}}",
                        .open = "{{",
                        .close = "}}",
                        .sep = " "
                      )
)

#minute_table <- in_schema("eviction_addresses", "tulsa_eviction_minutes")
#document_table <- in_schema("eviction-addresses", "document")

#res <- ojodb |>
#	dbGetQuery("select * from pg_stat_ssl where pid = pg_backend_pid();")

#cli_alert_info("{res}")

#message(bq_user())

#* Refreshes materialized views
#* @get /refresh
function(res) {
  refresh_cases_query <- "REFRESH MATERIALIZED VIEW eviction_addresses.recent_tulsa_evictions"
  refresh_minutes_query <- "REFRESH MATERIALIZED VIEW eviction_addresses.recent_tulsa_eviction_minutes"
  
  cases_res <- dbExecute(ojodb, refresh_cases_query)
  cli_alert_info("Cases refreshed: {cases_res} rows affected")
  minutes_res <- dbExecute(ojodb, refresh_minutes_query)
  cli_alert_info("Minutes refreshed: {minutes_res} rows affected")
  
  return()
}


#* Calls the database for eviction cases in Tulsa with no address. Store them in a BigQuery table
#* @get /hydrate
function(res) {
  query <- "SELECT * FROM eviction_addresses.document WHERE internal_link IS NULL ORDER BY created_at"
  links <- dbGetQuery(ojodb, query)
  
  if(nrow(links) == 0) {
    msg <- "No new documents to retrieve"
    cli_alert_info(msg)
    res$status <- 200
    return(list(status = "success", message = msg))
  }
  
  cli_progress_bar("Downloading and storing documents", total = nrow(links))
  for(i in 1:nrow(links)) {
    cli_alert_info("Starting link {i}")
    document <- GET(links[i, "link"]) |>
      pluck(content)
    if(is.na(document)) {
      cli_alert_info('No pdf found at {links[i, "link"]}')
      next()
    }
    cli_alert_success("Got pdf content {i}")
    upload <- gcs_upload(document,
                         name = links[i, "id"] |> pull(),
                         bucket = "eviction-addresses",
                         type = "application/pdf",
                         object_function = function(input, output) {
                           write_file(input, output)
                         },
                         predefinedAcl = "bucketLevel")
    cli_alert_success("Uploaded pdf {i}")
    internal_link <- gcs_download_url(links[i, "id"] |> pull(),
                                      bucket = "eviction-addresses",
                                      public = T)
    cli_alert_success("Got public link {i}")
    query <- glue('UPDATE eviction_addresses.document SET internal_link = "{internal_link}" WHERE id = \'{links[i, "id"] |> pull()}\'')
    dbExecute(ojodb, query)

    cli_alert_success("Completed link {i}/{nrow(links)}")
    cli_progress_update()
  }
  
  return()
}


# Serving the client:
# The only data going back and forth is a GET call to plumber which provides the client with case info, a link to the case-specific OSCN page, and an image of the Forcible Entry and Detainer (FED) document.
# Then a POST call which delivers an address to the api for storage.

#* Get a new case that has no address, return its id
#* @get /case
#* @serializer text
function() {
  # res <- tbl(con, "case") |>
  #   arrange(desc(created_at)) |>
  #   head(1) |>
  #   collect()
  
  res <- dbGetQuery(
    ojodb,
    "SELECT id FROM eviction_addresses.case ORDER BY RANDOM() LIMIT 1;"
  )

  return(res)
}

#* Take an HTML form as input and return an indicator of validation
#* @post /address/validate
#* @param street_num
#* @param street_dir
#* @param street_name
#* @param street_type
#* @param unit
#* @param city
#* @param state
#* @param zip
function(street_num = "", street_dir = "", street_name = "", street_type = "",
         unit = "", city = "", state = "", zip = "") {
  
  street <- str_c(street_num, street_dir, street_name, street_type, sep = " ")
  rusps::validate_address_usps(street = street, city = city, state = state, username = "952OKPOL2725")

  #ggmap::geocode(str_c(street, city, state, zip, sep = " "), source = "google", output = "all")
}

