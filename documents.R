library(googleCloudStorageR)
library(dplyr)
library(stringr)
library(ojodb)

# Auth
googleCloudStorageR::gcs_auth(json = "service-account.json")

# get objs
objs <- googleCloudStorageR::gcs_list_objects(bucket = "eviction-addresses", detail = "full")

data <- ojo_tbl("minute") |>
  left_join(
    ojo_tbl("case") |>
      select(
        id,
        district,
        case_number,
        date_filed,
        date_closed,
        updated_at
      ),
    by = c("case_id" = "id"),
    suffix = c(".minute", ".case")
  ) |>
  right_join(
    objs,
    by = c("id" = "name"),
    copy = TRUE
  ) |>
  collect()

data |>
  filter(
    str_detect(code, "FED") |
      (str_detect(description, "^FED") |
        str_detect(description, "^FORC"))
  ) |>
  count(
    code,
    sort = TRUE
  )

data |>
  mutate(
    is_forc = str_detect(code, "FED") |
      (str_detect(description, "^FED") |
        str_detect(description, "^FORC")),
    is_summons = str_detect(code, "^AFDC")
  ) |>
  summarise(
    .by = "case_id",
    has_forc = any(is_forc, na.rm = TRUE),
    has_summons = any(is_summons, na.rm = TRUE)
  ) |>
  count(
    has_forc,
    has_summons
  ) |>
  summarise(
    total_n = sum(n),
    forc_n = sum(if_else(has_forc, n, 0L)),
    summons_n = sum(if_else(has_summons, n, 0L)),
    neither_n = sum(if_else(!has_forc & !has_summons, n, 0L))
  ) |>
    mutate(
    percent_has_forc = (forc_n / total_n) * 100,
    percent_has_summons = (summons_n / total_n) * 100,
    perc_has_neither = (neither_n / total_n) * 100,
    .keep = "none"
  )

data |>
  slice_min(
    by = case_id,
    order_by = date,
    n = 1
  ) |>
  count(
    code,
    sort = TRUE
  )
