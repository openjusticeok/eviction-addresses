#' @title Get Sessions from DB
#' @description Gets a tibble of sessions from the database for use by {shinyauth}
#'
#' @param db The database connection
#' @param cookie_expiry The cookie expiration
#'
#' @returns A tibble of session info
#'
#' @importFrom rlang .data
#'
get_sessions_from_db <- function(db, cookie_expiry = 7) {
  f <- function(expiry = cookie_expiry) {
    logger::log_debug("Getting sessions from db")
    DBI::dbGetQuery(
      conn = db,
      dbplyr::sql('SELECT * FROM "eviction_addresses"."session"')
    ) |>
      dplyr::mutate(login_time = lubridate::ymd_hms(.data$login_time)) |>
      tibble::as_tibble() |>
      dplyr::filter(.data$login_time > lubridate::now(tzone = "America/Chicago") - lubridate::days(cookie_expiry))
  }
  return(f)
}


#' @title Add Session to DB
#' @description Adds a session to the database for {shinyauth}
#'
#' @param db A database connection Pool
#'
#' @returns Returns invisibly if successful
#'
add_session_to_db <- function(db) {
  f <- function(user, sessionid) {
    logger::log_debug("Adding session to db")
    values <- tibble::tibble(
      user = user,
      sessionid = sessionid,
      login_time = as.character(lubridate::now(tzone = "America/Chicago")))
    logger::log_trace("{values}")
    DBI::dbWriteTable(
      conn = db,
      name = DBI::Id(schema = "eviction_addresses", table = "session"),
      value = values,
      append = TRUE,
      row.names = FALSE
    )
    logger::log_debug("Wrote session to database table 'session'")
  }

  return(f)
}


#' @title Get Users from DB
#' @description Gets a tibble of users from the database to be used by {shinyauth}
#'
#' @param db A database connection pool created with `pool::dbPool`
#'
#' @returns A tibble of user info
#'
get_users_from_db <- function(db) {
  logger::log_debug("Getting users from db")
  DBI::dbGetQuery(
    conn = db,
    statement = dbplyr::sql('SELECT * FROM "eviction_addresses"."user"')
  ) |>
    tibble::as_tibble()
}

#' @title New User
#'
#' @description Adds a new user to the database
#'
#' @param db A database connection pool created with `pool::dbPool`
#' @param username The username
#' @param password The password
#' @param role The role of the user; either "admin" or "standard"
#' @param name The name of the user
#'
#' @export new_user
#' @returns Returns invisibly if successful
#'
#' @importFrom sodium password_store
#'
#' @examples
#' \dontrun{
#' new_user(db, "test", "test", "admin", "Test User")
#' }
#'
new_user <- function(db, username, password, role, name) {
    # Hash the password using {sodium}
    hashed_password <- sodium::password_store(password)

    role <- rlang::arg_match(
      role,
      c("admin", "user"),
      multiple = FALSE
    )

    # Store the user record in the user table
    user_record <- tibble::tibble(
      user = username,
      password_hash = hashed_password,
      role = role,
      name = name,
      created_at = lubridate::now(tzone = "America/Chicago"),
      updated_at = lubridate::now(tzone = "America/Chicago")
    )

    DBI::dbWriteTable(
      conn = db,
      name = DBI::Id(schema = "eviction_addresses", table = "user"),
      value = user_record,
      append = TRUE,
      row.names = FALSE
    )
}

#' @title Change Password
#'
#' @description Changes a user's password
#'
#' @param db A database connection pool created with `pool::dbPool`
#' @param username The username
#' @param old_password The old password
#' @param new_password The new password
#'
#' @export change_password
#' @returns Returns invisibly if successful
#'
#' @importFrom sodium password_verify password_store
#'
#' @examples
#' \dontrun{
#' change_password(db, "test", "test", "test2")
#' }
#'
change_password <- function(db, username, old_password, new_password) {
  # Check whether the old password is correct
  query <- glue::glue_sql(
    'SELECT "password_hash" FROM "eviction_addresses"."user" WHERE "user" = {username}',
    .con = db
  )

  old_password_hash <- DBI::dbGetQuery(
    conn = db,
    statement = query
  ) |>
    tibble::as_tibble() |>
    dplyr::pull(.data$password_hash)

  verified <- sodium::password_verify(hash = old_password_hash, password = old_password)

  if (!verified) {
    stop("Old password is incorrect")
  }

  # Hash the new password with {sodium}
  new_password_hash <- sodium::password_store(new_password) #nolint

  # Update the user record in the user table
  query <- glue::glue_sql(
    'UPDATE "eviction_addresses"."user" SET "password_hash" = {new_password_hash} WHERE "user" = {username}',
    .con = db
  )

  DBI::dbExecute(
    conn = db,
    statement = query
  )
}

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
plot_logins <- function(db, users, start = lubridate::ymd("2022-12-12"), end = lubridate::today()) {
  # Query the sessions table by users and date

  # Plot
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
      'SELECT "user", COUNT(*) AS "count" FROM "eviction_addresses"."process_log" WHERE "user" IN ({users*}) AND "created_at" BETWEEN {start} AND {end} GROUP BY "user"',
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
render_pay_report <- function() {

}
