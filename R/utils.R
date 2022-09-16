#' @title Has Names
#'
#' @param x The object to check for names
#' @param names A character vector of names to check `x` for
#'
#' @return A boolean (logical vector of length 1)
#' @export
#'
has_names <- function(x, names) {
  assert_that(
    is.character(names),
    length(names) >= 1
  )

  name_checks <- rep(F, length.out = length(names))
  for(i in 1:length(names)) {
    if(assertthat::has_name(x, names[i])) {
      name_checks[i] <- T
    }
  }

  if(all(name_checks)) {
    return(T)
  }

  return(F)
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
    mturk_auth()
  )
}

