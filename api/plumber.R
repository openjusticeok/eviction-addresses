library(plumber)
library(tidyverse)
library(future)
library(promises)
library(bigrquery)

plan(multisession)
bigrquery::bq_auth(
  path = "ojo-database-641c4256497c.json"
)

# The only data going back and forth is a GET call to plumber which provides the client with case info, a link to the case-specific OSCN page, and an image of the Forcible Entry and Detainer (FED) document.
# Then a POST call which delivers an address to the api for storage.

#* Calls the database(?) for eviction cases in Tulsa with no address. Store them in a BigQuery table
#* @get /hydrate
function() {
  future_promise({
    Sys.sleep(5)
    print("Hello world")
  })
}

#* Trigger a function to download the FED, store it in Cloud Storage, and create a public link. Store the link with the data in BiqQuery.
#* @post /fed/document
#* @param case_num
function(case_num = as.character(NA)) {
  if(!is.na(case_num)) {
    
  }
  return()
}

#* Get a new case that has no address, return its id
#* @get /case
function() {
  con <- dbConnect(
    bigrquery::bigquery(),
    project = "ojo-database",
    dataset = "ojo_eviction_addresses"
  )
  on.exit(dbDisconnect(con))

  res <- tbl(con, "case") |>
    arrange(desc(created_at)) |>
    head(1) |>
    collect()

  return(res)
}

#* Take an HTML form as input and return an indicator of validation
#* @post /address
#* @param street_num
#* @param street_dir
#* @param street_name
#* @param street_type
#* @param unit
#* @param city
#* @param zip
function(street_num = "", street_dir = "", street_name = "", street_type = "",
         unit = "", city = "", zip = "") {
  return(
    str_c(
      street_num, street_dir, street_name, street_type, ",",
      unit, ",",
      city, ",OK", zip
    )
  )
}


