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
library(jsonlite)

options(gargle_verbosity = "debug")
#options(future.globals.onReference = "error")
options(future.globals.seed = TRUE)
plan("multisession")

if(Sys.getenv("PORT") == "") {
  Sys.setenv(PORT = 8000)
}

log_threshold("DEBUG")
log_appender(appender_tee("test.log"))

create_pool <- function(connection_args) {
  new_pool <- pool::dbPool(odbc::odbc(),
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
  return(new_pool)
}

postgrid_key_type <- function(key) {
  if(str_detect(key, "^test")) {
    return("test")
  } else if(str_detect(key, "^live")) {
    return("live")
  } else {
    return(NULL)
  }
}

active_config <- function() {
  ac <- Sys.getenv("R_CONFIG_ACTIVE")
  if(ac == "") {
    return("default")
  } else {
    return(ac)
  }
}

log_debug("[CONFIG]: Active config is {active_config()}")

postgrid_args <- config::get('postgrid')

log_debug("[CONFIG]: Postgrid API key is set to '{postgrid_key_type(postgrid_args$key)}'")

connection_args <- config::get('database')
ojodb <- create_pool(connection_args)
#on.exit(pool::poolClose(ojodb))

# res <- ojodb |>
# dbGetQuery("select * from pg_stat_ssl where pid = pg_backend_pid();")
# 
# log_info("{res}")


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
    log_appender(appender_tee("test.log"))
    
    ojodb <- create_pool(connection_args)
    on.exit(pool::poolClose(ojodb))
    
    test <- dbGetQuery(ojodb, "SELECT NULL as n")
    log_info("Going to sleep now")
    Sys.sleep(10)
    return()
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
  future_promise({
    log_appender(appender_tee("test.log"))
    
    ojodb <- create_pool(connection_args)
    on.exit(pool::poolClose(ojodb))
    
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
    
    ## Remove any queue rows where success is true and it's 2 weeks old
    ## ? Should we check whether the address is found in the db ?
    
    query <- sql("DELETE FROM eviction_addresses.queue WHERE success IS TRUE AND created_at < current_timestamp - interval '14 days';")
    num_deleted_queue_rows <- DBI::dbExecute(ojodb, query)
    log_info("{num_deleted_queue_rows} rows deleted")
    
    
    ## Get any cases in case table without an address
    ## and having at least one document, are not in queue
    query <- sql(r"(SELECT DISTINCT(d."case"), NULL::bool AS success, NULL::bool AS working, 0::int4 AS attempts, NULL::timestamp AS started_at, NULL::timestamp AS stopped_at, current_timestamp AS created_at FROM eviction_addresses."document" d LEFT JOIN eviction_addresses.queue q ON d."case" = q."case" WHERE internal_link IS NOT NULL AND q."case" IS NULL;)")
    new_jobs <- dbGetQuery(ojodb, query)
    
    num_new_jobs <- nrow(new_jobs)
    
    if(num_new_jobs >= 1) {
      dbAppendTable(
        conn = ojodb,
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
  
  return()
}


#* Calls the database for eviction cases in Tulsa with no address. Store them in a BigQuery table
#* @get /hydrate
function(res) {
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
    #sql("SELECT id FROM eviction_addresses.case ORDER BY RANDOM() LIMIT 1;")
    sql('SELECT "case" FROM eviction_addresses.document WHERE internal_link IS NOT NULL ORDER BY RANDOM() LIMIT 1;')
  )
  
  log_trace("Served new case number to client")
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
  
  address <- list()
  address$line1 <- str_c(street_num, street_dir, street_name, street_type, sep = " ")
  address$line2 <- unit
  address$city <- city
  address$provinceOrState <- state
  address$postalOrZip <- zip
  address$country <- "us"
  
  #### Postgrid ####
  
  parse_postgrid_response <- function(res) {
    body <- content(res, as = "parsed", type = "application/json")
    if(body$status != "success") {
      log_error("[PostGrid]: {body$status}")
      stop()
    }
    
    log_info("[PostGrid]: {body$message}")
    log_info("[PostGrid]: {body$data$status}")
    
    num_parsing_errors <- length(body$data$errors)
    if(num_parsing_errors != 0) {
      log_error("[PostGrid]: {num_parsing_errors} error(s)")
      log_error("[Postgrid]: {body$data$errors |> unlist()}")
    }
    
    parsed_address <- list(
      line1 = body$data$line1,
      line2 = body$data$line2,
      streetName = body$data$details$streetName,
      streetType = body$data$details$streetType,
      streetDirection = body$data$details$streetDirection,
      preDirection = body$data$details$preDirection,
      streetNumber = body$data$details$streetNumber,
      suiteID = body$data$details$suiteID,
      suiteKey = body$data$details$suiteKey,
      city = body$data$city,
      county = body$data$details$county,
      state = body$data$provinceOrState,
      country_code = body$data$country,
      country_name = body$data$countryName,
      zip = body$data$postalOrZip,
      zip4 = body$data$zipPlus4,
      lat = body$data$geocodeResult$location$lat,
      lon = body$data$geocodeResult$location$lng,
      geo_accuracy = body$data$geocodeResult$accuracy,
      geo_accuracy_type = body$data$geocodeResult$accuracyType,
      residential = body$data$details$residential,
      vacant = body$data$details$vacant,
      firm_name = body$data$firmName
    )
    
  }
  
  #address <- fromJSON(address)
  
  req_body <- list(
    address = address
  ) |>
    toJSON(auto_unbox = T)
  
  url <- "https://api.postgrid.com/v1/addver/verifications?includeDetails=true&geocode=true"
  res <- POST(
    url,
    add_headers(`x-api-key` = postgrid_args$key),
    content_type_json(),
    accept_json(),
    body = req_body,
    encode = "form"
  )
  parsed_res <- res |>
    parse_postgrid_response()
  
  return(parsed_res)
}

