#' @title Plot Logins
#' 
#' @description Plots the number of logins per day
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param users A vector of users to plot
#' @param start The start date
#' @param end The end date
#' 
#' @export plot_logins
#' @returns A ggplot object
#' 
#' @importFrom lubridate ymd today
#' 
#' @examples
#' \dontrun{
#' plot_logins(db, c("test", "test2"), lubridate::ymd("2022-12-12"), lubridate::today())
#' }
#'
plot_logins <- function(db, users, start = lubridate::ymd("2022-12-12"), end = lubridate::today(), .silent = FALSE) {
  # Query the sessions table by users and date
    query <- glue::glue_sql(
        'SELECT "user", DATE("created_at") AS "date", COUNT(*) AS "count" FROM "eviction_addresses"."sessions" WHERE "user" IN ({users}) AND "created_at" BETWEEN {start} AND {end} GROUP BY "user", DATE("created_at")',
        .con = db
    )

    # Store the result in a tibble
    logins <- DBI::dbGetQuery(db, query)

  # Plot
    p <- ggplot2::ggplot(logins, ggplot2::aes(x = date, y = count, color = user)) +
        ggplot2::geom_line() +
        ggplot2::labs(x = "Date", y = "Number of Logins", color = "User") +
        ggplot2::theme_bw()
    
    # Print if not silent
    if (!.silent) { print(p) }
    
    return(p)
}

#' @title Plot Address Entries
#' 
#' @description Plots the number of address entries per day
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param users A vector of users to plot
#' @param start The start date
#' @param end The end date
#' @param type The type of address entry to plot; either "priority" or "backlog"
#' 
#' @export plot_address_entries
#' @returns A ggplot object
#' 
#' @importFrom lubridate ymd today
#' 
#' @examples
#' \dontrun{
#' plot_address_entries(db, c("test", "test2"), lubridate::ymd("2022-12-12"), lubridate::today(), "priority")
#' }
#' 
plot_address_entries <- function(db, users, start = lubridate::ymd("2022-12-12"), end = lubridate::today(), type) {
  # Query count of address entries by users and creation time
}

#' @title Calculate Pay
#' 
#' @description Calculates the pay for a given user
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param users A vector of users to plot
#' @param start The start date
#' @param end The end date
#' 
#' @export calculate_pay
#' @returns A tibble with the number of addresses entered by type and the corresponding pay
#' 
#' @importFrom rlang .data
#' 
#' @examples
#' \dontrun{
#' calculate_pay(db, c("test", "test2"), lubridate::ymd("2022-12-12"), lubridate::today())
#' }
#' 
calculate_pay <- function(db, users, start, end) {
    # Query process table for number of addresses entered per person and entry type
    query <- glue::glue_sql(
      'SELECT "user", "type", COUNT(*) AS "count" FROM "eviction_addresses"."process_log" WHERE "user" IN ({users}) AND "created_at" BETWEEN {start} AND {end} GROUP BY "user", "type"',
      .con = db
    )

    entry_counts <- DBI::dbGetQuery(
      conn = db,
      statement = query
    ) |>
      tibble::as_tibble()

    # Define pay rates
    priority_rate <- 0.15
    backlog_rate <- 0.10

    # Multiply counts by rates for corresponding type
    entry_counts <- entry_counts |>
      dplyr::mutate(
        priority_pay = dplyr::case_when(
          .data$type == "priority" ~ .data$count * priority_rate,
          TRUE ~ 0
        ),
        backlog_pay = dplyr::case_when(
          .data$type == "backlog" ~ .data$count * backlog_rate,
          TRUE ~ 0
        ),
        total_pay = .data$priority_pay + .data$backlog_pay
      )
    
    return(entry_counts)
}

#' @title Render Pay Report
#' 
#' @description Renders a pay report for a given user
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param users A vector of users to plot
#' @param start The start date
#' @param end The end date
#' 
#' @export render_pay_report
#' @returns A tibble with the number of addresses entered by type and the corresponding pay
#' 
render_pay_report <- function(db, users, start, end) {
  # Calculate pay
  pay <- calculate_pay(db, users, start, end)

  # Render report
  report <- pay |>
    dplyr::group_by(.data$user) |>
    dplyr::summarise(
      total_pay = sum(.data$total_pay)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      total_pay = paste0("$", .data$total_pay)
    )

  return(report)
}
