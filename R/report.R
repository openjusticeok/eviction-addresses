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
        'SELECT "user", DATE("login_time") AS "date", COUNT(*) AS "count"',
        'FROM "eviction_addresses"."session"',
        'WHERE "user" IN ({users*})',
        'AND "login_time" BETWEEN {start} AND {end}',
        'GROUP BY "user", DATE("login_time")',
        .sep = " ",
        .con = db
    )

    # Store the result in a tibble
    # Convert the count column to numeric from integer64
    logins <- DBI::dbGetQuery(db, query) |>
      dplyr::mutate(count = as.numeric(.data$count))

    # Plot
    p <- ggplot2::ggplot(logins, ggplot2::aes(x = date, y = count, fill = user)) +
        ggplot2::geom_col() +
        ggplot2::facet_wrap(ggplot2::vars(.data$user)) +
        ggplot2::labs(x = "Date", y = "Number of Logins", color = "User") +
        ggplot2::theme_bw()
    
    # Print if not silent
    if (!.silent) { print(p) }
    
    return(p)
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
calculate_pay <- function(db, users, start, end, priority_rate = 0.35, backlog_rate = 0.25) {
    # Query process table for number of addresses entered per person and entry type
    query <- glue::glue_sql(
      'SELECT "user", DATE(pl.created_at) as created_at, c.date_filed',
      'FROM "eviction_addresses"."process_log" pl',
      'LEFT JOIN eviction_addresses."case" c on pl."case" = c.id',
      'WHERE "user" IN ({users*})',
      'AND pl.created_at BETWEEN {start} AND {end};',
      .sep = " ",
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

    # Count number of entries per user and type
    entry_counts <- res |>
      dplyr::count(
        .data$user,
        .data$type
      )

    # Multiply counts by rates for corresponding type
    entry_counts <- entry_counts |>
      tidyr::pivot_wider(
        id_cols = c("user"),
        names_from = "type",
        values_from = "n",
        names_glue = "{type}_n"
      ) |>
      dplyr::mutate(
        priority_pay = .data$priority_n * priority_rate,
        backlog_pay = .data$backlog_n * backlog_rate
      ) |>
      dplyr::mutate(
        dplyr::across(
          is.numeric,
          ~ tidyr::replace_na(., 0)
        )
      ) |>
      dplyr::mutate(
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

  # Render table
  tb <- pay |>
    dplyr::group_by(.data$user) |>
    dplyr::summarise(
      total_pay = sum(.data$total_pay)
    ) |>
    gt::gt()

  return(tb)
}

#' @title Email Pay Report
#' 
#' @description Emails a pay report for the given users using the package `{blastula}`
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param users A vector of users to plot
#' @param start The start date
#' @param end The end date
#' @param email The email address to send the report to
#' 
#' @export email_pay_report
#' @returns Nothing
#' 
email_pay_report <- function(db, users, start, end, recipient_email) {
  # Render report
  report <- render_pay_report(db, users, start, end)

  # Create email
  email_content <- blastula::compose_email(
    body = report,
    footer = "This is an automated email. Please do not reply."
  )

  # Send email
  blastula::smtp_send(
    email = email_content,
    to = recipient_email,
    from = "bgregory@okpolicy.org",
    subject = "Data Entry Contractors Pay Report",
    credentials = blastula::creds_file(file = here::here("blastula.json"))
  )

  return()
}


#' @title Plot Address Coverage
#' 
#' @description Calculates the number of addresses entered
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param ... Additional arguments placeholder
#' @param .silent A boolean indicating whether to print the plot
#' 
#' @export
#' @returns A tibble with the number of addresses entered by month
#' 
plot_address_coverage <- function(db, ..., .silent = FALSE) {
  # Query the case and address tables to find the number of cases with and without addresses
  query <- glue::glue_sql(
    "SELECT date_trunc('month', ca.date_filed) as \"month\", 'false' AS \"has_address\", COUNT(*) as n",
    "FROM ( select * from eviction_addresses.\"case\" c left join eviction_addresses.address a on c.id = a.\"case\") ca",
    "WHERE ca.\"case\" IS null",
    "group by \"month\"",
    "UNION",
    "SELECT date_trunc('month', ca.date_filed) as \"month\", 'true' AS \"has_address\", COUNT(*)",
    "FROM ( select * from eviction_addresses.\"case\" c left join eviction_addresses.address a on c.id = a.\"case\") ca",
    "WHERE ca.\"case\" IS not null",
    "group by \"month\"",
    "order by \"month\";",
    .sep = " ",
    .con = db
  )

  # Get results
  res <- DBI::dbGetQuery(
    conn = db,
    statement = query
  ) |>
    tibble::as_tibble()
  
  # Plot
  p <- res |> 
    dplyr::mutate(
      month = lubridate::ymd(.data$month),
      n = as.numeric(.data$n)
    ) |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$month,
        y = .data$n,
        fill = .data$has_address
      )
    ) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(
      values = c(
        "false" = "red",
        "true" = "green"
      )
    ) +
    ggplot2::labs(
      x = "Month",
      y = "Number of Addresses",
      fill = "Has Address?"
    ) +
    ggplot2::theme_bw()

  # Print if not silent
  if (!.silent) { print(p) }

  return(p)
}


#' @title Plot Address Entries
#' 
#' @description Calculates the number of addresses entered
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param ... Additional arguments placeholder
#' @param .silent A boolean indicating whether to print the plot
#' 
#' @export
#' @returns A ggplot object
#' 
plot_address_entries <- function(db, ..., .silent = FALSE) {
  # Addresses entered per week
  query <- glue::glue_sql(
    "select date_trunc('week', created_at) as \"week\", count(*) as n",
    "from eviction_addresses.process_log pl",
    "group by \"week\"",
    "order by \"week\";",
    .sep = " ",
    .con = db
  )

  # Get results
  res <- DBI::dbGetQuery(
    conn = db,
    statement = query
  ) |>
    tibble::as_tibble()

  # Plot
  p <- res |> 
    dplyr::mutate(
      week = lubridate::ymd(.data$week),
      n = as.numeric(.data$n)
    ) |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$week,
        y = .data$n
      )
    ) +
    ggplot2::geom_col() +
    ggplot2::labs(
      x = "Week",
      y = "Number of Addresses"
    ) +
    ggplot2::theme_bw()

  # Print if not silent
  if (!.silent) {
    print(p)
  }

  return(p)
}

#' @title Plot Address Lag
#' 
#' @description Calculates the time from a case being filed to an address being entered
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param ... Additional arguments placeholder
#' @param .silent A boolean indicating whether to print the plot
#' 
#' @export
#' @returns A ggplot object
#' 
plot_address_lag <- function(db, ..., .silent = FALSE) {
  # Time from date_filed to date address entered
  query <- glue::glue_sql(
    "SELECT date_trunc('week', c.date_filed) as \"week_filed\", AVG(DATE_PART('day', AGE(pl.created_at, c.date_filed))) as \"avg_lag_days\"",
    "FROM eviction_addresses.\"case\" c",
    "INNER JOIN eviction_addresses.process_log pl",
    "ON c.id = pl.\"case\"",
    "WHERE date_filed >= '2022-12-01'",
    "GROUP BY \"week_filed\"",
    "ORDER BY \"week_filed\";",
    .sep = " ",
    .con = db
  )

  # Get results
  res <- DBI::dbGetQuery(
    conn = db,
    statement = query
  ) |>
    tibble::as_tibble()

  # Plot
  p <- res |> 
    dplyr::mutate(
      week_filed = lubridate::ymd(.data$week_filed),
      # avg_lag_days = as.numeric(.data$avg_lag_days)
    ) |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$week_filed,
        y = .data$avg_lag_days
      )
    ) +
    ggplot2::geom_col() +
    ggplot2::labs(
      x = "Week",
      y = "Average Days to Enter Address"
    ) +
    ggplot2::theme_bw()

  # Print if not silent
  if (!.silent) {
    print(p)
  }

  return(p)
}

#' @title Plot Cases
#' 
#' @description Calculates the number of cases filed per month
#' 
#' @param db A database connection pool created with `pool::dbPool`
#' @param ... Additional arguments placeholder
#' @param .silent A boolean indicating whether to print the plot
#' 
#' @export
#' @returns A ggplot object
#' 
plot_cases <- function(db, ..., .silent = FALSE) {
  # Num evictions per month
  query <- glue::glue_sql(
    "SELECT date_trunc('month', c.date_filed) as \"month_filed\", COUNT(*) as n",
    "FROM eviction_addresses.\"case\" c",
    "GROUP BY \"month_filed\"",
    "ORDER BY \"month_filed\";",
    .sep = " ",
    .con = db
  )

  # Get results
  res <- DBI::dbGetQuery(
    conn = db,
    statement = query
  ) |>
    tibble::as_tibble()

  # Plot
  p <- res |> 
    dplyr::mutate(
      month_filed = lubridate::ymd(.data$month_filed),
      n = as.numeric(.data$n)
    ) |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$month_filed,
        y = .data$n
      )
    ) +
    ggplot2::geom_col() +
    ggplot2::labs(
      x = "Month",
      y = "Number of Cases"
    ) +
    ggplot2::theme_bw()

  # Print if not silent
  if (!.silent) {
    print(p)
  }

  return(p)
}
