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
#' @export
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

#' @title Add New User
#'
#' @description Adds a new user to the database
#'
#' @param db A database connection pool created with `pool::dbPool`
#' @param username The username
#' @param password The password
#' @param role The role of the user; either "admin" or "standard"
#' @param name The name of the user
#' @param full_name The full name of the user
#' @param organization The organization of the user
#' @param email The email of the user
#' @param line1 The address line 1 of the user
#' @param line2 The address line 2 of the user
#' @param city The city of the user
#' @param state The state of the user
#' @param zip The zip code of the user
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
new_user <- function(
  db,
  username,
  password,
  role,
  name,
  full_name,
  organization,
  email,
  line1,
  line2,
  city,
  state,
  zip
) {
    if (!is.character(username) || length(username) != 1L || is.na(username) || username == "") {
      stop("`username` must be a single, non-missing, non-empty character value.", call. = FALSE)
    }

    if (!grepl("^[A-Za-z]+$", username)) {
      stop("`username` must contain only alphabetical letters.", call. = FALSE)
    }

    # Hash the password using {sodium}
    hashed_password <- sodium::password_store(password)

    role <- rlang::arg_match(
      role,
      c("admin", "user"),
      multiple = FALSE
    )

    users <- get_users_from_db(db)

    if (any(users$user == username, na.rm = TRUE)) {
      stop("`username` already exists. Choose a different username.", call. = FALSE)
    }

    # Store the user record in the user table
    user_record <- tibble::tibble(
      user = username,
      password_hash = hashed_password,
      role = role,
      name = name,
      full_name = full_name,
      organization = organization,
      email = email,
      line1 = line1,
      line2 = line2,
      city = city,
      state = state,
      zip = zip,
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

    message(glue::glue("✅ User '{username}' added successfully."))
    message("Please immediately store the username & password in OK Policy's Bitwarden vault.")
}

#' @title Delete User
#'
#' @description Removes one or more rows for a matching username from the
#' `eviction_addresses.user` table, with optional confirmation prompts.
#'
#' @param db A database connection pool created with `pool::dbPool`
#' @param username A single character string identifying the account to delete.
#' @param confirm Optional logical flag controlling confirmation prompts. Set to
#'   `TRUE` to delete without prompting, `FALSE` to cancel, or leave as `NULL` to
#'   prompt interactively.
#'
#' @returns Invisibly returns the number of rows deleted, or `0L` when no action
#'   is taken.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' delete_user(db, "demo-user", confirm = TRUE)
#' }
#'
#' @seealso [get_users_from_db()], [new_user()]
#'
#' @family dashboard-authentication
#'
#' @importFrom DBI dbExecute
#'
#' @importFrom glue glue_sql
#'
delete_user <- function(db, username, confirm = NULL) {
  users <- get_users_from_db(db)

  matching_users <- users |>
    dplyr::filter(user == username)

  if (nrow(matching_users) == 0) {
    warning("No matching user found for deletion.")
    return(invisible(0L))
  }

  preview_columns <- c("user", "full_name", "role", "created_at", "updated_at")
  preview <- matching_users |>
    dplyr::select(dplyr::any_of(preview_columns))

  message(
    "The following rows match the requested deletion:\n"
  )
  preview |>
    print(n = Inf)

  proceed <- FALSE

  if (isTRUE(confirm)) {
    proceed <- TRUE
  } else if (isFALSE(confirm)) {
    message("Deletion cancelled.")
    return(invisible(0L))
  } else {
    if (!interactive()) {
      stop("Set `confirm = TRUE` to proceed with deletion when running non-interactively.")
    }

    response <- utils::askYesNo("Proceed with deleting the rows shown above?", default = FALSE)

    if (!isTRUE(response)) {
      message("Deletion cancelled.")
      return(invisible(0L))
    }

    proceed <- TRUE
  }

  # Redundant check for safety
  if (!isTRUE(proceed)) {
    message("Deletion cancelled.")
    return(invisible(0L))
  }

  deletion_statement <- glue::glue_sql(
    'DELETE FROM "eviction_addresses"."user" WHERE "user" = {username}',
    .con = db
  )

  rows_deleted <- DBI::dbExecute(
    conn = db,
    statement = deletion_statement
  )

  message(glue::glue("🗑️ {rows_deleted} rows(s) deleted."))
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
