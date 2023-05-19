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
    updated_at <= "2023-05-01"
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


# Define a function to filter the data for each date
get_filtered_cases <- function(data, date, exclude_cases) {
  filtered_data <- data |>
    filter(
      date_filed >= date - days(15),
      date_entered >= date - days(5),
      date_entered <= date,
      !case %in% exclude_cases
    )

  return(filtered_data)
}

# Initialize an empty data frame for the result
result <- tibble(
  date = seq(as_date("2023-03-01"), as_date("2023-05-01"), by = "days"),
  case_ids = list(rep(character(), 62)),
  n = integer(length = 62)
)

# Iterate over the dates and apply the filtering criteria
excluded_cases <- c()
for (i in seq_along(result$date)) {
  filtered_data <- get_filtered_cases(
    data,
    result$date[i],
    excluded_cases
  )

  result <- result |>
    mutate(
      case_ids = if_else(
        date == result$date[i],
        list(filtered_data$case),
        case_ids
      ),
      n = if_else(
        date == result$date[i],
        nrow(filtered_data),
        n
      )
    )

  excluded_cases <- c(
    excluded_cases,
    filtered_data$case
  )
}

result |>
  ggplot(aes(x = date, y = n)) +
    geom_col() +
    labs(
      x = NULL,
      y = NULL,
      title = "Number of Letters Available to Send Each Day",
      caption = str_wrap(
        "A letter is available to be sent if the case was filed within the last 15 days and the address was entered within the last 5 days.",
        65
      )
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 90, hjust = 1)
    )

result |>
  unnest(case_ids) |>
  distinct() |>
  left_join(
    data,
    by = c("case_ids" = "case")
  ) |>
  distinct() |>
  mutate(
    days_to_ready = date - date_filed,
    rolling_avg_days_to_ready = cumsum(
      as.numeric(date - date_filed)
    ) / row_number()
  ) |>
  ggplot(
    aes(
      x = date,
      y = rolling_avg_days_to_ready
    )
  ) +
    geom_smooth(
      method = "loess",
      se = TRUE
    ) +
    geom_point(
      alpha = 0.2,
      size = 0.5
    ) +
    labs(
      x = NULL,
      y = NULL,
      title = "Average Days to Ready for Each Day",
      caption = str_wrap(
        "The average number of days between when a case is filed and when the address is entered into the system.",
        65
      )
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 90, hjust = 1)
    )

