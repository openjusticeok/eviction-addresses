library(evictionAddresses)
library(ojodb)
library(tidyverse)
library(lubridate)
library(gganimate)

# Load data
cases <- ojo_tbl("case") |>
  select(id, district, case_type, date_filed) |>
  filter(
    district == "TULSA",
    date_filed >= "2018-01-01",
    case_type == "SC"
  ) |>
  left_join(
    ojo_tbl("issue") |>
      select(id, description, case_id),
    by = c("id" = "case_id"),
    suffix = c("", ".issue")
  ) |>
  filter(
    str_detect(
      description,
      "EVICTION|(?:ENTRY.*(?:FORCIBLE|DETAINER))|(?:(?:FORCIBLE|DETAINER).*ENTRY)"
    )
  )

# Make sure we are only looking at Tulsa cases
addresses <- ojo_tbl("address", schema = "eviction_addresses") |>
  select(id, case, accuracy, created_at)

# Join addresses to cases
data <- cases |>
  left_join(
    addresses,
    by = c("id" = "case")
  ) |>
  collect()

# For each day from the first date_filed to today, count the number of cases which were filed on or before that day
# and add an indicator for whether or not an addresses' created_at date is on or before that day

data |>
  mutate(
    date_filed = as.Date(date_filed),
    created_at = as.Date(created_at),
    date = seq.Date(
      from = min(date_filed, na.rm = TRUE),
      to = Sys.Date(),
      by = "day"
    )
  ) |>
  group_by(date) |>
  mutate(
    cases = n(),
    addresses = sum(created_at <= date)
  ) |>
  ungroup()
