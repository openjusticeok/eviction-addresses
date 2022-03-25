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
library(here)
library(config)
library(odbc)
library(dbplyr)
library(dbx)
library(logger)

options(gargle_verbosity = "debug")
#options(future.globals.onReference = "error")
options(future.globals.seed = TRUE)
plan("multisession")

if(Sys.getenv("PORT") == "") {
  Sys.setenv(PORT = 8000)
}

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

res <- ojodb|>
dbGetQuery("select * from pg_stat_ssl where pid = pg_backend_pid();")

log_info("{res}")

#* Ping to show server is there
#* @get /ping
function() {
  log_success("pong")
  return()
}

#* Ping to show db is there
#* @get /dbping
function() {
  test <- dbGetQuery(ojodb, "SELECT NULL as n")
  
  log_success("db pong")
  return()
}

#* Ping to show db is there
#* @get /dbpingfuture
function() {
  future_promise({
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
    on.exit(pool::poolClose(ojodb))
    
    Sys.sleep(10)
    },
    seed = TRUE) |>
      then(
        function() {
          log_success("long db pong")
          return()
        }
      )
  
  return()
}

#* Refreshes materialized views
#* @get /refresh
function(res) {
  ## Refresh both materialized views to ingest new eviction cases and minutes
  refresh_cases_query <- "REFRESH MATERIALIZED VIEW eviction_addresses.recent_tulsa_evictions;"
  refresh_minutes_query <- "REFRESH MATERIALIZED VIEW eviction_addresses.recent_tulsa_eviction_minutes;"

  log_info("Starting case refresh")
  cases_res <- dbExecute(ojodb, refresh_cases_query)
  log_success("Cases refreshed: {cases_res} rows affected")
  
  log_info("Starting minute refresh")
  minutes_res <- dbExecute(ojodb, refresh_minutes_query)
  log_success("Minutes refreshed: {minutes_res} rows affected")
  
  ## Check whether there are new cases
  new_cases_query <- sql('SELECT DISTINCT(rte.id), rte.district, rte.case_type, rte.case_number, rte.date_filed, current_timestamp AS created_at, current_timestamp AS updated_at FROM eviction_addresses.recent_tulsa_evictions rte LEFT JOIN eviction_addresses."case" c ON rte.id = c.id WHERE c.id IS NULL;')
  log_info("Finding new cases")
  new_cases <- dbGetQuery(ojodb, new_cases_query)
  num_new_cases <- nrow(new_cases)
  log_info("Found {num_new_cases} new cases")
  
  ## Insert new cases into case table
  if(num_new_cases >= 1) {
    dbAppendTable(
      conn = ojodb,
      name = Id(schema = "eviction_addresses", table = "case"),
      value = new_cases
    )
    log_success("Inserted {num_new_cases} new cases to table eviction_addresses.case")
  }
  
  #Check whether there are new minutes
  new_minutes_query <- sql('SELECT DISTINCT(rtem.id), rtem."case", rtem.description, rtem.link, NULL AS internal_link, current_timestamp AS created_at, current_timestamp AS updated_at FROM eviction_addresses.recent_tulsa_eviction_minutes rtem LEFT JOIN eviction_addresses."document" d ON rtem.id = d.id WHERE d.id IS NULL;')
  log_info("Finding new minutes")
  new_minutes <- dbGetQuery(ojodb, new_minutes_query)
  num_new_minutes <- nrow(new_minutes)
  log_info("Found {num_new_minutes} new minutes")
  
  if(num_new_minutes >= 1) {
    dbAppendTable(
      conn = ojodb,
      name = Id(schema = "eviction_addresses", table = "document"),
      value = new_minutes
    )
    log_success("Inserted {num_new_minutes} new document minutes to table eviction_addresses.document")
  }
  
  return()
}


#* Calls the database for eviction cases in Tulsa with no address. Store them in a BigQuery table
#* @get /hydrate
function(res) {
  promises::future_promise({
  query <- sql("SELECT id, link FROM eviction_addresses.document WHERE internal_link IS NULL ORDER BY created_at;")
  links <- DBI::dbGetQuery(ojodb, query)
  
  if(nrow(links) == 0) {
    msg <- "No new documents to retrieve"
    log_info(msg)
    res$status <- 200
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
  }
  
  return()
  })
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
  
  res <- pool::dbGetQuery(
    ojodb,
    sql("SELECT id FROM eviction_addresses.case ORDER BY RANDOM() LIMIT 1;")
  )
  
  log_success("Got new case number")
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

