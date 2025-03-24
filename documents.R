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

res |>
      mutate(
        is_forc    = code == "FED", 
        is_summons = code == "AFDC1", is_nada = !is_forc & !is_summons
      ) |>
      summarise(
        .by = "case_id",
        perc_forc    = sum(is_forc, na.rm = true) / n() * 100,
        perc_summons = sum(is_summons, na.rm = true) / n() * 100, perc_nada = sum(is_nada, na.rm = true) / n() * 100
      ) |>
      summarise(
        perc_without_forc    = sum(perc_forc <= 0, na.rm = true) / n() * 100,
        perc_without_summons = sum(perc_summons <= 0, na.rm = true) / n() * 100, perc_without_nada = sum(perc_nada <= 0, na.rm = true) / n() * 100
      )

res |>
  slice_min(
    by = case_id,
    order_by = date,
    n = 1
  ) |>
  count(
    code,
    sort = TRUE
  )
