library(ojodb)
library(dplyr)
library(lubridate)
library(stringr)
library(ggplot2)
library(purrr)
library(zoo)
library(tidyr)

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

start_date <- as_date("2025-01-01")
end_date <- as_date("2026-03-24")

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
    filename = "avg_days_to_ready_full_project.png",
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
  summary()

###### Letter Timeliness Analysis
# Analyzing whether letters are being sent with enough time to impact eviction outcomes
# Started around 2025-12-01

# Define thresholds (days before disposition that letter is considered timely)
timeliness_threshold <- 4  # 4+ days = green/timely
yellow_threshold <- 1      # 1-3 days = yellow (too late to impact)

# Prepare data for timeliness analysis
timeliness_data <- data |>
  mutate(
    # Calculate days between letter entry and disposition (will be NA for pending cases)
    days_before_disposition = as.numeric(as_date(disposition_date) - date_entered),
    # Categorize timeliness with 4 categories
    timeliness_category = case_when(
      is.na(disposition_date) ~ "Timely or Pending",
      days_before_disposition <= 0 ~ "On or After Disposition",
      days_before_disposition >= yellow_threshold & days_before_disposition < timeliness_threshold ~ "1-3 Days Before",
      days_before_disposition >= timeliness_threshold ~ "Timely or Pending",
      TRUE ~ NA_character_
    ),
    # Period indicator (before/after Amanda Faith's team)
    period = if_else(date_filed >= as_date("2025-12-01"), "After Dec 1, 2025", "Jan 1, 2025 - Dec 1, 2025")
  )

# Summary table by timeliness category
summary_table <- timeliness_data |>
  count(timeliness_category, period) |>
  group_by(period) |>
  mutate(
    pct = round(n / sum(n) * 100, 1),
    total_cases = sum(n)
  ) |>
  ungroup() |>
  arrange(period, desc(n))

summary_table

# Overall timeliness rates by period
period_summary <- timeliness_data |>
  group_by(period) |>
  summarise(
    total_cases = n(),
    timely_or_pending_count = sum(timeliness_category == "Timely or Pending"),
    yellow_count = sum(timeliness_category == "1-3 Days Before"),
    late_count = sum(timeliness_category == "On or After Disposition"),
    pct_timely_or_pending = round(timely_or_pending_count / total_cases * 100, 1),
    pct_yellow = round(yellow_count / total_cases * 100, 1),
    pct_late = round(late_count / total_cases * 100, 1),
    median_days_before = median(days_before_disposition, na.rm = TRUE),
    mean_days_before = round(mean(days_before_disposition, na.rm = TRUE), 1)
  )

period_summary

# Visualization 1: Distribution of days before disposition
timeliness_plot <- ggplot(timeliness_data, aes(x = days_before_disposition, fill = period)) +
  geom_histogram(binwidth = 2, alpha = 0.7, position = "identity") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", alpha = 0.7) +
  geom_vline(xintercept = yellow_threshold - 1, linetype = "dashed", color = "orange", alpha = 0.7) +
  geom_vline(xintercept = timeliness_threshold, linetype = "dashed", color = "green", alpha = 0.7) +
  annotate("text", x = yellow_threshold, y = Inf, label = "1-day\nthreshold", vjust = 2, size = 3) +
  annotate("text", x = timeliness_threshold + 1, y = Inf, label = "4-day\nthreshold", vjust = 2, size = 3) +
  facet_wrap(~period, ncol = 1) +
  labs(
    title = "Letter Timeliness: Days Before Disposition",
    subtitle = "Letters sent on/after disposition (red), 1-3 days before (yellow), or timely/pending (green)",
    x = "Days Before Disposition (negative = on or after disposition)",
    y = "Number of Cases",
    fill = "Period"
  ) +
  theme_minimal() +
  expand_limits(x = c(-10, 30))

timeliness_plot

# Visualization 2: Timeliness category breakdown by period
category_plot <- summary_table |>
  ggplot(aes(x = timeliness_category, y = pct, fill = timeliness_category)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = sprintf("%s\n(%s%%)", n, pct)), vjust = -0.5, size = 3) +
  facet_wrap(~period) +
  labs(
    title = "Operational Changes are Improving Letter Timeliness",
    subtitle = "Letter Timeliness by Category",
    x = NULL,
    y = "Percentage of Cases"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_manual(values = c(
    "On or After Disposition" = "#d62728",
    "1-3 Days Before" = "#ffbb78",
    "Timely or Pending" = "#2ca02c"
  ))

category_plot

# Save plots
timeliness_plot |>
  ggsave(
    filename = "letter_timeliness_distribution_year.png",
    plot = _,
    width = 10,
    height = 8,
    units = "in",
    dpi = 300
  )

category_plot |>
  ggsave(
    filename = "letter_timeliness_categories_year.png",
    plot = _,
    width = 12,
    height = 6,
    units = "in",
    dpi = 300
  )

# Summary of median days by period
print("\nMedian days before disposition by period:")
timeliness_data |>
  filter(!is.na(disposition_date)) |>
  group_by(period) |>
  summarise(
    median_days = median(days_before_disposition, na.rm = TRUE),
    mean_days = round(mean(days_before_disposition, na.rm = TRUE), 1),
    n = n()
  ) |>
  print()

###### Project Phases Analysis
# Identify periods of activity vs inactivity using monthly phases
# This provides stable, interpretable periods for analysis

# Calculate daily entry counts
daily_activity <- data |>
  filter(!is.na(date_entered)) |>
  count(date_entered, name = "entries") |>
  complete(
    date_entered = seq(min(date_entered), max(date_entered), by = "day"),
    fill = list(entries = 0)
  )

# Calculate 7-day rolling average
daily_activity <- daily_activity |>
  mutate(
    rolling_7day = zoo::rollmean(entries, k = 7, fill = NA, align = "right"),
    # Create monthly phase labels (Year-Month format)
    phase = format(date_entered, "%Y-%m"),
    # Add a more readable label
    phase_label = format(date_entered, "%b %Y")
  )

# Activity level classification within each phase (month)
phase_stats <- daily_activity |>
  group_by(phase, phase_label) |>
  summarise(
    phase_mean_activity = mean(rolling_7day, na.rm = TRUE),
    phase_total_entries = sum(entries),
    activity_level = if_else(phase_mean_activity >= 5, "Active (5+ avg/day)", "Inactive (<5 avg/day)"),
    start_date = min(date_entered),
    end_date = max(date_entered),
    .groups = "drop"
  )

# Join back to daily_activity
daily_activity <- daily_activity |>
  left_join(
    phase_stats |> select(phase, phase_label, phase_mean_activity, phase_total_entries, activity_level),
    by = c("phase", "phase_label")
  )

# Get phase transition dates (first day of each month)
phase_dates <- daily_activity |>
  group_by(phase) |>
  summarise(start_date = min(date_entered), .groups = "drop") |>
  arrange(start_date) |>
  filter(row_number() > 1)  # Exclude the first date

# Visualization 1: Activity over time with monthly phases
activity_plot <- ggplot(daily_activity, aes(x = date_entered, y = rolling_7day)) +
  geom_line(aes(color = phase_label), linewidth = 1) +
  geom_point(aes(color = phase_label), alpha = 0.5, size = 2) +
  geom_hline(yintercept = 5, linetype = "dashed", color = "gray50", alpha = 0.7) +
  geom_vline(data = phase_dates,
             aes(xintercept = as.numeric(start_date)),
             linetype = "dotted", color = "red", alpha = 0.5) +
  annotate("text",
           x = phase_dates$start_date,
           y = max(daily_activity$rolling_7day, na.rm = TRUE) * 0.95,
           label = format(phase_dates$start_date, "%b"),
           angle = 90, vjust = -0.5, size = 3, color = "red") +
  labs(
    title = "Project Activity by Month: 7-Day Rolling Average of Address Entries",
    subtitle = "Monthly phases shown by color, month transitions marked with dotted red lines",
    x = "Date",
    y = "7-Day Rolling Average (Entries/Day)",
    color = "Month"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(activity_plot)

# Add phase information to timeliness data
timeliness_with_phases <- timeliness_data |>
  left_join(
    daily_activity |> select(date_entered, phase, phase_label, activity_level, phase_mean_activity),
    by = "date_entered"
  )

# Summary table by phase - ensure chronological order
phase_summary <- timeliness_with_phases |>
  filter(!is.na(phase_label)) |>
  group_by(phase_label, activity_level) |>
  summarise(
    total_cases = n(),
    timely_or_pending_count = sum(timeliness_category == "Timely or Pending", na.rm = TRUE),
    yellow_count = sum(timeliness_category == "1-3 Days Before", na.rm = TRUE),
    late_count = sum(timeliness_category == "On or After Disposition", na.rm = TRUE),
    pct_timely_or_pending = round(timely_or_pending_count / total_cases * 100, 1),
    pct_yellow = round(yellow_count / total_cases * 100, 1),
    pct_late = round(late_count / total_cases * 100, 1),
    avg_daily_entries = round(mean(phase_mean_activity, na.rm = TRUE), 1),
    month_order = min(date_entered),  # Store actual date for ordering
    date_range = paste(format(min(date_entered, na.rm = TRUE), "%b %d"),
                      "to",
                      format(max(date_entered, na.rm = TRUE), "%b %d")),
    .groups = "drop"
  ) |>
  arrange(month_order)

print("\nTimeliness by Project Phase:")
print(phase_summary)

# Get ordered phase labels for proper plotting
ordered_phases <- phase_summary$phase_label

# Visualization 2: Timeliness rates by phase
timeliness_by_phase_plot <- phase_summary |>
  select(phase_label, activity_level, date_range, pct_timely_or_pending, pct_yellow, pct_late) |>
  pivot_longer(cols = starts_with("pct_"), names_to = "metric", values_to = "percentage") |>
  mutate(
    metric = case_when(
      metric == "pct_timely_or_pending" ~ "Timely or Pending",
      metric == "pct_yellow" ~ "1-3 Days Before",
      metric == "pct_late" ~ "On or After Disposition"
    ),
    metric = factor(metric, levels = c("On or After Disposition", "1-3 Days Before", "Timely or Pending")),
    # Ensure phase_label is ordered chronologically
    phase_label = factor(phase_label, levels = ordered_phases)
  ) |>
  ggplot(aes(x = phase_label, y = percentage, fill = metric)) +
  geom_col(position = "stack") +
  geom_text(aes(label = sprintf("%s%%", percentage)),
            position = position_stack(vjust = 0.5), size = 3) +
  labs(
    title = "Operational Friction Drives Drastic Volatility in Letter Timeliness Goals",
    subtitle = "Percentage of Cases Meeting Timeliness Standards by Month",
    x = "Month",
    y = "Percentage of Cases",
    fill = "Timeliness"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_manual(values = c(
    "On or After Disposition" = "#d62728",
    "1-3 Days Before" = "#ffbb78",
    "Timely or Pending" = "#2ca02c"
  ))

print(timeliness_by_phase_plot)

# Combined view: Activity and timeliness over time
combined_plot <- ggplot() +
  # Activity line
  geom_line(data = daily_activity, aes(x = date_entered, y = rolling_7day * 10, color = "Activity"), linewidth = 1) +
  # Timeliness rate (7-day rolling % of timely or pending)
  geom_smooth(data = timeliness_with_phases |>
                mutate(is_timely = timeliness_category == "Timely or Pending") |>
                group_by(date_entered) |>
                summarise(pct_timely = mean(is_timely, na.rm = TRUE) * 100, .groups = "drop"),
              aes(x = date_entered, y = pct_timely, color = "Timeliness Rate"),
              method = "loess", se = FALSE, linewidth = 1) +
  # Add month boundaries
  geom_vline(data = phase_dates,
             aes(xintercept = as.numeric(start_date)),
             linetype = "dotted", color = "red", alpha = 0.5) +
  scale_y_continuous(
    name = "Timeliness Rate (%)",
    sec.axis = sec_axis(~./10, name = "Daily Entries (7-day avg)")
  ) +
  scale_color_manual(values = c("Activity" = "blue", "Timeliness Rate" = "darkgreen")) +
  labs(
    title = "Project Activity and Timeliness Over Time",
    subtitle = "Activity (blue) vs Timeliness Rate (green), with month boundaries (dotted red lines)",
    x = "Date"
  ) +
  theme_minimal()

print(combined_plot)

# Detailed phase characteristics
print("\nMonthly Phase Characteristics:")
phase_characteristics <- daily_activity |>
  group_by(phase_label) |>
  summarise(
    start_date = min(date_entered),
    end_date = max(date_entered),
    duration_days = as.numeric(end_date - start_date) + 1,
    total_entries = sum(entries),
    avg_daily_entries = round(mean(rolling_7day, na.rm = TRUE), 1),
    max_daily_entries = max(rolling_7day, na.rm = TRUE),
    min_daily_entries = min(rolling_7day, na.rm = TRUE),
    activity_level = first(activity_level),
    .groups = "drop"
  ) |>
  arrange(phase_label)

print(phase_characteristics)

