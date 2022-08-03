library(ojodb)
library(dm)
library(jsonlite)
library(logger)

postgrid_args$key <- ""

old_addresses <- ojo_tbl("old_db_temp", schema = "eviction_addresses")
case_table <- ojo_tbl("case")
migrate_table <- ojo_tbl("address_migrate", schema = "eviction_addresses")

id_lookup <- ojodb |>
  dbGetQuery(
    read_file("inst/sql/case_match.sql")
  ) |>
  as_tibble()

dbCreateTable(
  ojodb,
  Id(schema = "eviction_addresses", table = "id_lookup"),
  fields = id_lookup
)

dbxInsert(
  ojodb,
  Id(schema = "eviction_addresses", table = "id_lookup"),
  records = id_lookup
)

lookup_table <- ojo_tbl("id_lookup", "eviction_addresses")

old_temp <- old_addresses |>
  left_join(
    lookup_table,
    by = c("court", "casenum", "file_date")
  ) |>
  left_join(
    case_table,
    by = c("id")
  ) |>
  select(
    id,
    court,
    casenum,
    file_date,
    addr,
    city,
    lon,
    lat,
    addr_method,
    zip,
    addr_google,
    case_type,
    case_number,
    date_filed
  ) |>
  collect()



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

geocode_address <- function(addr, city, zip) {
  address <- list()
  address$line1 <- addr
  address$city <- city
  address$provinceOrState <- "ok"
  address$postalOrZip <- zip
  address$country <- "us"

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

data <- old_temp |>
  mutate(
    geocode = pmap(
      list(addr, city, zip),
      geocode_address
    )
  )

# write_csv(data, "data.csv")

upload_data <- data |>
  select(
    case = id,
    street_number = streetNumber,
    street_direction = streetDirection,
    street_name = streetName,
    street_type = streetType,
    street_unit = ,
    city = `city...24`,
    state = state,
    zip = `zip...29`,
    #created_at = created_at,
    #updated_at = updated_at,
    street_full = c(),
    line1,
    line2,
    pre_direction = preDirection,
    suite_id = suiteID,
    suite_key = suiteKey,
    county = county,
    country_code,
    country_name,
    zip4,
    lat = `lat...31`,
    lon = `lon...32`,
    geo_accuracy,
    geo_accuracy_type,
    residential,
    vacant,
    firm_name
  ) |>
  left_join(
    old_temp |>
      mutate(
        method = case_when(
          str_detect(addr_method, "MANUAL|APARTMENT") ~ "manual",
          str_detect(addr_method, "OCR") ~ "ocr",
          T ~ addr_method
        ),
        accuracy = case_when(
          addr_method == "APARTMENT NAME" ~ "building",
          T ~ "mailing"
        ),
        geo_service = "postgrid"
      ) |>
      select(id, method, accuracy, geo_service),
    by = c("case" = "id")
  )

dbAppendTable(
  ojodb,
  Id(
    schema = "eviction_addresses",
    table = "address_migrate"
  ),
  upload_data |>
    filter(
      !is.na(case)
    ) |>
    mutate(
      created_at = now(),
      updated_at = now()
    )
)

address_table <- ojo_tbl(table = "address", "eviction_addresses")

## These are new ones to add to the migrate table
new_table <- anti_join(address_table, migrate_table) |>
  select(
    case,
    line1,
    line2,
    street_name,
    street_type,
    street_direction,
    pre_direction,
    street_number,
    suite_id,
    suite_key,
    city,
    county,
    state,
    country_code,
    country_name,
    zip,
    zip4,
    lat,
    lon,
    geo_accuracy,
    geo_accuracy_type,
    residential,
    vacant,
    firm_name,
    created_at,
    updated_at
  ) |>
  mutate(
    method = "manual",
    accuracy = "mailing",
    geo_service = "postgrid"
  ) |>
  collect() |>
  group_by(case) |>
  arrange(case, desc(created_at)) |>
  slice(1) |>
  ungroup() |>
  anti_join(
    migrate_table |>
      collect(),
    by = c("case")
  )

# inner_join(migrate_table |> collect(), new_table)

dbAppendTable(
  ojodb,
  Id(schema = "eviction_addresses", table = "address_migrate"),
  new_table
)

############ Migrate Checks ##############

eviction_table <- ojo_tbl(table = "recent_tulsa_evictions", "eviction_addresses")

old_table <- ojo_tbl(table = "old_db_temp", "eviction_addresses")
lookup_table <- ojo_tbl(table = "id_lookup_temp", "eviction_addresses")
old_table <- old_table |>
  left_join(lookup_table)

## Nothing in address table that isn't in migrate table
anti_join(address_table, migrate_table, by = c("case")) |>
  count()

## These 844 have no matching id to their casenums
anti_join(old_table, migrate_table, by = c("id" = "case")) |>
  count()

## 7873 eviction cases without addresses
anti_join(eviction_table, migrate_table)

