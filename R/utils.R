#' @title Has Names
#'
#' @param x The object to check for names
#' @param names A character vector of names to check `x` for
#'
#' @returns A boolean (logical vector of length 1)
#'
#' @import assertthat
#'
has_names <- function(x, names) {
  assert_that(
    is.character(names),
    length(names) >= 1
  )

  name_checks <- rep(FALSE, length.out = length(names))
  for(i in seq_along(names)) {
    if(assertthat::has_name(x, names[i])) {
      name_checks[i] <- TRUE
    }
  }

  if(all(name_checks)) {
    return(TRUE)
  }

  return(FALSE)
}


#' @title Skip If No Config
#'
skip_if_no_config <- function() {
  testthat::skip_if_not(
    file.exists("config.yml")
  )
}


#' @title Skip if no database access
#'
skip_if_no_db <- function() {
  skip_if_no_config()

  tryCatch(
    db <- new_db_pool(),
    error = function(err) {
      return(err)
    }
  )

  if(inherits(db, "error")) {
    testthat::skip()
  }

  withr::defer(pool::poolClose(db))

  testthat::skip_if_not(
    pool::dbIsValid(db)
  )
}


#' @title Expect No Error
#'
#' @param object An object passed to `testthat::expect_error()`
#'
expect_no_error <- function(object) {
  testthat::expect_error(
    object = object,
    regexp = NA
  )
}


#' @title Has Lat/Lon Match
#'
#' @param .data A tibble with columns `lat` and `lon`
#' @param tolerance A numeric >= 0
#'
#' @returns A boolean
#'
#' @import assertthat
#'
has_latlon_match <- function(.data, tolerance = 0.0002) {
  assert_that(
    has_names(.data, c("lat", "lon"))
  )
  # Need to check whether there are at least two similar enough lat/lons
  lats <- .data[["lat"]]
  lons <- .data[["lon"]]

  assert_that(
    length(lats) == length(lons),
    noNA(lats),
    noNA(lons)
  )

  m <- matrix(data = FALSE, nrow = length(lats), ncol = length(lats))

  for (i in seq_along(lats)) {
    for (j in seq_along(lats)[-i]) {
      m[i,j] <- ifelse(
        isTRUE(all.equal(lats[i], lats[j], tolerance = tolerance, scale = 1)),
        TRUE,
        FALSE
      )
    }
  }

  if(any(m)) {
    inds <- which(m, arr.ind = TRUE)[1, ] |> as.list()

    res <- all.equal(lons[inds$row], lons[inds$col], tolerance = tolerance, scale = 1)
    return(isTRUE(res))
  }

  return(FALSE)
}

#' @title Get Pay Period
#' 
#' @description Gets the pay period for a given date
#' 
#' @param date A date
#' @param pay_period_start_date The reference start date for pay periods. Defaults to a Sunday (2023-01-01)
#' @param period The length of the pay period as a string (e.g., "1 week", "2 weeks", "1 month"). Defaults to "1 week"
#' 
#' @export
#' @returns
#' A list with two values `start` and `end` which
#' are the first and last days of the pay period containing `date`.
#' Pay periods start on Sunday and go through Saturday.
#' 
get_pay_period <- function(date, pay_period_start_date = lubridate::ymd("2023-01-01"), period = "1 week") {
  if(!inherits(date, "Date")) {
    if(!inherits(date, "character")) {
      stop("`date` must be a character or Date")
    }

    date <- lubridate::ymd(date)
  }

  # Parse the period string into days
  period_duration <- lubridate::duration(period)
  period_days <- as.integer(period_duration / lubridate::ddays(1))
  
  if(period_days <= 0) {
    stop("`period` must result in a positive number of days")
  }

  diff_date <- (date - pay_period_start_date) |> as.integer()

  pay_period <- diff_date %/% period_days

  start <- pay_period_start_date + (pay_period * period_days)
  end <- start + period_days - 1

  res <- list(
    start = start,
    end = end
  )

  return(res)
}
