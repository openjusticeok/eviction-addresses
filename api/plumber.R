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

db <- pool::dbPool(odbc::odbc(),
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
on.exit(dbDisconnect(db))

minute_table <- in_schema("eviction_addresses", "tulsa_eviction_minutes")
document_table <- in_schema("eviction-addresses", "document")

res <- ojodb |>
	dbGetQuery("select * from pg_stat_ssl where pid = pg_backend_pid();")

cli_alert_info("{res}")

#message(bq_user())

#* Calls the database(?) for eviction cases in Tulsa with no address. Store them in a BigQuery table
#* @get /hydrate
function() {
  con <- dbConnect(
    bigquery(),
    project = "ojo-database",
    dataset = "ojo_eviction_addresses"
  )
  on.exit(dbDisconnect(con))
  
  query <- "SELECT * FROM `ojo-database.ojo_eviction_addresses.document` WHERE internal_link IS NULL ORDER BY created_at"
  links <- dbGetQuery(con, query)
  
  cli_progress_bar("Downloading and storing documents", total = nrow(links))
  for(i in 1:nrow(links)) {
    cli_alert_info("Starting link {i}")
    document <- GET(links[i, "link"] |> pull()) |>
      pluck(content)
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
    query <- glue('UPDATE `ojo-database.ojo_eviction_addresses.document` SET internal_link = "{internal_link}" WHERE id = \'{links[i, "id"] |> pull()}\'')
    dbExecute(con, query)

    cli_alert_success("Completed link {i}/{nrow(links)}")
    cli_progress_update()
  }
  
  return()
}


#* Trigger a function to download a document, store it in Cloud Storage, and create a public link. Store the link with the data in BiqQuery.
#* @post /document
#* @param case_id
function(case_id = as.character(NA)) {
  if(is.na(case_id)) {
    
  }
  con <- dbConnect(
    bigquery(),
    project = "ojo-database",
    dataset = "ojo_eviction_addresses"
  )
  on.exit(dbDisconnect(con))
  
  
  
  return()
}



# Serving the client:
# The only data going back and forth is a GET call to plumber which provides the client with case info, a link to the case-specific OSCN page, and an image of the Forcible Entry and Detainer (FED) document.
# Then a POST call which delivers an address to the api for storage.

#* Get a new case that has no address, return its id
#* @get /case
#* @serializer text
function() {
  con <- dbConnect(
    bigquery(),
    project = "ojo-database",
    dataset = "ojo_eviction_addresses"
  )
  on.exit(dbDisconnect(con))

  # res <- tbl(con, "case") |>
  #   arrange(desc(created_at)) |>
  #   head(1) |>
  #   collect()
  
  res <- dbGetQuery(con,
                    "SELECT id FROM `ojo_eviction_addresses.case` ORDER BY RAND() LIMIT 1;")

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

#* Take an HTML form as input and return an indicator of success
#* @post /address/submit
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
  
  
  
  return(
    str_c(
      street_num, street_dir, street_name, street_type, ",",
      unit, ",",
      city, state, zip,
      sep = " "
    )
  )
}
