#' @title Has Names
#'
#' @param x The object to check for names
#' @param names A character vector of names to check `x` for
#'
#' @return A boolean (logical vector of length 1)
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


#' @title Skip if MTurk cannot authenticate
#'
skip_if_no_mturk <- function() {
  testthat::skip_if_not(
    mturk_auth(config = "config.yml")
  )
}


#' @title Skip if no database access
#'
skip_if_no_db <- function() {
  skip_if_no_config()

  tryCatch(
    db <- new_db_pool(),
    error = function(err) {
      err
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

#' @title Launch Worker Sandbox
#'
launch_worker_sandbox <- function() {
  url <- "https://workersandbox.mturk.com/requesters/A1IQJE205A4RN2/projects"
  browseURL(url)

  invisible(url)
}


#' @title Has Lat/Lon Match
#'
#' @param .data A tibble with columns `lat` and `lon`
#' @param tolerance A numeric >= 0
#'
#' @return A boolean
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
