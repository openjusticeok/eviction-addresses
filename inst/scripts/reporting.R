library(ojoverse)
library(tidyverse)
library(purrr)

# Load and preprocess data
load_preprocess_data <- function(start_date, end_date) {
  data <- ojo_tbl("process_log", schema = "eviction_addresses") |>
    filter(
      updated_at >= start_date - days(15),
      updated_at <= end_date
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
      by = c("case" = "id"),
      suffix = c(".process_log", ".case")
    ) |>
    left_join(
      ojo_tbl("issue"),
      by = c("case" = "case_id"),
      suffix = c(".case", ".issue")
    ) |>
    select(
      case,
      date_entered,
      date_filed,
      date_closed,
      created_at = created_at.issue,
      disposition,
      disposition_date
    ) |>
    mutate(
      date_scraped = floor_date(created_at, "day") |>
        as_date(),
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

  return(data)
}

# Filter cases based on date and exclusion list
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

# Generate results for plotting
get_result_data <- function(data, start_date, end_date) {
  num_days <- as.numeric(end_date - start_date) + 1

  # Initialize an empty data frame for the result
  result <- tibble(
    date = seq(start_date, end_date, by = "day"),
    n = rep(0, num_days),
    case_ids = rep(list(character(0)), num_days)
  )

  # Iterate over the dates and apply the filtering criteria
  excluded_cases <- c()
  for (i in seq_along(result$date)) {
    filtered_data <- get_filtered_cases(
      data,
      result$date[i],
      excluded_cases
    )

    result$n[i] <- nrow(filtered_data)
    result$case_ids[[i]] <- filtered_data$case

    excluded_cases <- c(
      excluded_cases,
      filtered_data$case
    )
  }

  return(result)
}

# Plot number of letters available to send each day
plot_letters_each_day <- function(result) {
  ggplot(result, aes(x = date, y = n)) +
    geom_col() +
    labs(
      x = NULL,
      y = NULL,
      title = "Number of Letters Available to Send Each Day",
      subtitle = str_wrap(
        "A letter is available to be sent if the case was filed within the last 15 days and the address was entered within the last 5 days.",
        65
      )
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 90, hjust = 1)
    )
}

# Plot average days to ready for each day
plot_avg_days_to_ready <- function(data, result) {
  min_points <- 15 # Minimum number of points to calculate rolling average

  data_to_plot <- result |>
    unnest(case_ids) |>
    distinct() |>
    left_join(
      data,
      by = c("case_ids" = "case")
    ) |>
    distinct() |>
    arrange(date) |>
    mutate(
      days_to_ready = date - date_filed,
      rolling_avg_days_to_ready = if_else(
        row_number() >= min_points,
        cumsum(as.numeric(date - date_filed)) / row_number(),
        NA_real_
      )
    )

  ggplot(data_to_plot, aes(x = date, y = rolling_avg_days_to_ready)) +
    geom_smooth(method = "loess", se = TRUE) +
    geom_jitter(alpha = 0.2, size = 0.5, height = 0, width = 0.3) +
    labs(
      x = NULL,
      y = NULL,
      title = "Average Days to Ready for Each Day",
      subtitle = str_wrap(
        "The average number of days between when a case is filed and when the address is entered into the system.",
        65
      )
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 90, hjust = 1)
    )
}



# Main script

start_date <- as_date("2023-04-01")
end_date <- as_date("2023-04-30")

data <- load_preprocess_data(
  start_date = start_date,
  end_date = end_date
)

result <- get_result_data(
  data,
  start_date = start_date,
  end_date = end_date
)

plot1 <- plot_letters_each_day(result)
plot2 <- plot_avg_days_to_ready(data, result)

plot1
plot2 + expand_limits(y = 0)

plot2 |>
  ggsave(
    filename = "avg_days_to_ready.png",
    plot = _,
    width = 8,
    height = 6,
    units = "in",
    dpi = 300
  )

result |>
  unnest(case_ids) |>
  distinct() |>
  left_join(
    data,
    by = c("case_ids" = "case")
  ) |>
  distinct() |>
  arrange(date) |>
  mutate(
    days_to_ready = date - date_filed
  ) |>
  group_by(date) |>
  summarise(
    avg_days_to_ready = mean(days_to_ready)
  )

min_points <- 15 # Minimum number of points to calculate rolling average

data_to_plot <- result |>
  unnest(case_ids) |>
  distinct() |>
  left_join(
    data,
    by = c("case_ids" = "case")
  ) |>
  distinct() |>
  arrange(date) |>
  mutate(
    days_to_ready = date - date_filed,
    rolling_avg_days_to_ready = if_else(
      row_number() >= min_points,
      cumsum(as.numeric(date - date_filed)) / row_number(),
      NA_real_
    )
  )

ggplot(data_to_plot, aes(x = date_filed, y = days_to_ready)) +
  geom_jitter(alpha = 0.1) +
  labs(
    x = NULL,
    y = NULL,
    title = "Average Days to Ready for Each Day",
    subtitle = str_wrap(
      "The average number of days between when a case is filed and when the address is entered into the system.",
      65
    )
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1)
  )

data_to_plot |>
  mutate(
    days_to_ready = as.numeric(days_to_ready)
  ) |>
  pull(days_to_ready) |>
  skimr::skim()
