library(ojoverse)
library(tidyverse)

# Asemio logic for filtering what addresses to send letters for
# case was filed within the last 15 days
# case address data was added within the last 5 days

# For each day of the month
#  - get all cases filed in the last 15 days
#  - get all addresses added in the last 5 days

# Ex. March 2023
# - get all addresses added between 2023-02-24 and 2023-03-31
# - get all cases filed between 2023-02-14 and 2023-03-31

data <- ojo_tbl("process_log", schema = "eviction_addresses") |>
  filter(
    updated_at >= "2023-02-24",
    updated_at <= "2023-03-31"
  ) |>
  mutate(
    date_entered = floor_date(created_at, "day") |>
      as_date(),
  ) |>
  select(
    case,
    date_entered
  ) |>
  left_join(
    ojo_tbl("case"),
    by = c("case" = "id")
  ) |>
  left_join(
    ojo_tbl("issue"),
    by = c("case" = "case_id")
  ) |>
  select(
    case,
    date_filed,
    date_entered,
    disposition_date,
    disposition
  ) |>
  mutate(
    clean_disposition = case_when(
      str_detect(disposition,  "DISMISS") ~ "DISMISSED",
      str_detect(disposition,  "JUDGMENT|JUDGEMENT") ~
        case_when(
          str_detect(disposition,  "DEFAULT") ~ "DEFAULT JUDGMENT",
          str_detect(disposition,  "PLAINTIFF") ~ "JUDGMENT FOR PLAINTIFF",
          str_detect(disposition,  "DEFENDANT") ~ "JUDGMENT FOR DEFENDANT",
          TRUE ~ "JUDGMENT ENTERED"
        ),
      str_detect(disposition,  "ADVISEMENT") ~ "UNDER ADVISEMENT",
      is.na(disposition) ~ NA_character_,
      TRUE ~ "OTHER"
    )
  ) |>
  mutate(
    judgment = case_when(
      clean_disposition %in% c("DEFAULT JUDGMENT", "JUDGMENT FOR PLAINTIFF") ~ "Landlord",
      clean_disposition == "JUDGMENT FOR DEFENDANT" ~ "Tenant",
      clean_disposition == "JUDGMENT ENTERED" ~ "Decided, Outcome Unknown",
      clean_disposition == "DISMISSED" ~ "Dismissed (Settled Outside Court)",
      !is.na(clean_disposition) ~ "Decided, Outcome Unknown",
      TRUE ~ NA_character_
    )
  ) |>
  select(-disposition) |>
  ojo_collect()

# For each day of the month create a table of cases filed in the last 15 days with addresses added in the last 5 days
tibble(
  day = seq.Date(
    from = as.Date("2023-02-24"),
    to = as.Date("2023-03-31"),
    by = "day"
  )
) |>
  mutate(
    ready_to_send = accumulate(
      day,
      ~ data |>
        filter(
          date_filed >= (as_date(.y) - days(15)),
          date_filed <= as_date(.y),
          date_entered >= (as_date(.y) - days(5)),
        ) |>
        pull(case) |>
        unique()
    )
  )

# Define a function to filter the data for each date
get_filtered_cases <- function(data, date, exclude_cases) {
  filtered_data <- data %>%
    filter(
      date_filed >= date - days(15),
      date_entered >= date - days(5),
      !case %in% exclude_cases
    )
  return(filtered_data)
}

# Initialize an empty data frame for the result
result <- tibble(
  date = seq(as_date("2023-03-01"), as_date("2023-03-31"), by = "days"),
  case_ids = list(rep(character(), 31)),
  n = integer(length = 31)
)

# Iterate over the dates and apply the filtering criteria
excluded_cases <- c()
for (i in seq_along(result)) {
  filtered_data <- get_filtered_cases(
    data,
    result[i, "date"] |> pull(),
    excluded_cases
  )

  result[i, "case_ids"] <- list(filtered_data$case)

  excluded_cases <- c(
    excluded_cases,
    filtered_data$case
  )
}
