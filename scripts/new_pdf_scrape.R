library(ojodb)
library(httr2)
library(logger)
library(progress)

# log_appender(appender_tee("test.log"))
# googleCloudStorageR::gcs_auth(json_file = "eviction-addresses-service-account.json", email = "bq-test@ojo-database.iam.gserviceaccount.com")

ojo_connect()

query <- sql("SELECT id, link FROM eviction_addresses.document WHERE internal_link IS NULL ORDER BY created_at;")
links <- DBI::dbGetQuery(ojodb, query)

links$link |>
  map(~paste0("test", .))

ua <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"

res <- request(links$link[1]) |>
  req_user_agent(ua) |>
  req_headers(
    Referer = "https://www.oscn.net/v4/"
  ) |>
  req_throttle(rate = 1/2) |>
  req_retry(
    max_tries = 3,
    is_transient = function(res) {
      !resp_content_type(res) == "application/pdf"
    }
  ) |>
  req_perform()

get_document <- function(link) {
  link <- str_replace(link, "fmt=pdf$", "fmt=tif")
  request(link) |>
    req_user_agent("dtSearchSpider") |>
    req_headers(
      Referer = "https://www.oscn.net/v4/"
    ) |>
    req_throttle(rate = 1/4) |>
    req_retry(
      max_tries = 3,
      is_transient = function(res) {
        !resp_content_type(res) == "image/tiff"
      }
    ) |>
    req_perform()
}

get_document_slowly <- slowly(
  get_document,
  rate = rate_delay(pause = 5, max_times = Inf)
)

map_progress <- function(.x, .f, ...) {
  .f <- purrr::as_mapper(.f, ...)
  pb <- progress::progress_bar$new(total = length(.x), force = TRUE)
  
  f <- function(...) {
    pb$tick()
    .f(...)
  }
  purrr::map(.x, f, ...)
}

test <- links$link |>
  head(10) |>
  map_progress(get_document_slowly)


