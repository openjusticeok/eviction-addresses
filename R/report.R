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
        'SELECT "user", DATE("login_time") AS "date", COUNT(*) AS "count" FROM "eviction_addresses"."session" WHERE "user" IN ({users}) AND "login_time" BETWEEN {start} AND {end} GROUP BY "user", DATE("login_time")',
        .con = db
    )

    # Store the result in a tibble
    # Convert the count column to numeric from integer64
    logins <- DBI::dbGetQuery(db, query) |>
      dplyr::mutate(count = as.numeric(.data$count))

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
calculate_pay <- function(
  db,
  users = "all",
  start = get_pay_period(lubridate::today())$start,
  end = get_pay_period(lubridate::today())$end,
  priority_rate = 0.35,
  backlog_rate = 0.25
) {
  # Query process table for number of addresses entered per person and entry type
  query <- glue::glue_sql(
    'SELECT "user", DATE(pl.created_at) as created_at, c.date_filed ',
    'FROM "eviction_addresses"."process_log" pl ',
    'left join eviction_addresses."case" c ',
    'on pl."case" = c.id ',
    'WHERE ',
    if (!users == "all") {'"user" IN ({users*}) AND '} else "",
    'pl.created_at BETWEEN {start} AND {end}',
    ';',
    .con = db
  )

  res <- DBI::dbGetQuery(
    conn = db,
    statement = query
  ) |>
    tibble::as_tibble()

  # Calculate diff between created_at and date_filed and derive entry type
  res <- res |>
    dplyr::mutate(
      days_diff = .data$created_at - .data$date_filed
    ) |>
    dplyr::mutate(
      type = dplyr::case_when(
        .data$days_diff <= 14 ~ "priority",
        TRUE ~ "backlog"
      )
    )

  rates <- tibble::tibble(
    type = c("priority", "backlog"),
    rate = c(priority_rate, backlog_rate)
  )

  # Count number of entries per user and type
  entry_counts <- res |>
    dplyr::group_by(.data$user, .data$type) |>
    dplyr::count() |>
    dplyr::ungroup() |>
    dplyr::left_join(rates, by = "type") |>
    dplyr::select(-.data$user) |>
    dplyr::mutate(
      pay = .data$n * .data$rate,
      type = stringr::str_to_title(.data$type),
    ) |>
    gt::gt() |>
    gt::cols_label(
      n = "Quantity",
      type = "Description",
      rate = "Rate",
      pay = "Cost"
    ) |>
    gt::fmt_currency(
      columns = c("rate", "pay"),
      currency = "USD",
      decimals = 2
    ) |>
    gt::grand_summary_rows(
      columns = c("n"),
      fns = list(
        TOTAL = ~sum(.)
      ),
      formatter = gt::fmt_integer,
      use_seps = FALSE
    ) |>
    gt::grand_summary_rows(
      columns = c("pay"),
      fns = list(
        TOTAL = ~sum(.)
      ),
      formatter = gt::fmt_currency,
      use_seps = FALSE
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
render_pay_report <- function(
  db,
  users = "all",
  start = get_pay_period(lubridate::today())$start,
  end = get_pay_period(lubridate::today())$end
) {
  # Calculate pay
  pay <- calculate_pay(db, users, start, end)



  return(report)
}

#' @title Render Project Report
#' 
#' @description Renders a project report for a given user
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param users A vector of users to plot
#' @param start The start date
#' @param end The end date
#' 
#' @export
#' @returns A rendered project report
#' 
render_project_report <- function() {
  # TODO: Implement

  # Render report
  report <- "This is a project report"

  return(report)
}