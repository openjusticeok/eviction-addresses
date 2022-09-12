## These constants define valid statuses according to MTurk documentation
## They are used in functions that get statuses
valid_hit_statuses <- c("Assignable", "Unassignable", "Reviewable", "Reviewing", "Disposed")
valid_hit_review_statuses <- c("NotReviewed", "MarkedForReview", "ReviewedAppropriate", "ReviewedInappropriate")
valid_assignment_statuses <- c("Submitted", "Approved", "Rejected")


#' @title MTurk Authentication
#'
#' @param config A file path to a config.yml
#'
#' @return A logical/boolean representing whether we successfully connected to MTurk
#' @export
#'
#' @import assertthat
#'
#' @examples
#'
#' \dontrun{
#' try(mturk_auth())
#' try(mturk_auth(config = "config.yml"))
#' }
#'
mturk_auth <- function(config = NULL) {
  if(!is.null(config)) {
    logger::log_debug("Config file supplied; using config variables")

    aws_config <- config::get("aws", file = config)
    if(is.null(aws_config)) {
      logger::log_error("A config file path was supplied but no aws section found")
      return(invisible(F))
    }

    env_set <- Sys.setenv(
      AWS_ACCESS_KEY_ID = aws_config$key.id,
      AWS_SECRET_ACCESS_KEY = aws_config$key.secret
    )

    if(!all(env_set)) {
      logger::log_error("Failed to set environment variables")
      return(invisible(F))
    }
  } else {
    logger::log_debug("No config file supplied; using env variables")
  }

  check_auth <- pyMTurkR::CheckAWSKeys()
  assert_that(
    is.flag(check_auth)
  )

  if(check_auth) {
    logger::log_success("pyMTurkR found auth keys")
    return(invisible(T))
  }

  logger::log_error("pyMTurkR didn't find auth keys")
  return(invisible(F))
}


#' @title New HIT Type
#'
#' @param title The title for the HIT Type
#' @param description A description to be shown to workers
#' @param reward A string representing amount to be paid for successful completion in USD
#' @param duration The time in seconds that a worker has to complete the assignment
#' @param keywords A string with comma separated terms to be used to search for HITs of this type
#' @param auto.approval.delay The time in seconds after which a completed assignment is auto-approved
#' @param ... Additional arguments passed to `pyMTurkR::CreateHITType()`
#'
#' @return The HIT Type id
#' @export
#'
#' @import assertthat
#'
#' @examples
#'
#' \dontrun{
#' new_hit_type()
#' new_hit_type(reward = "0.20")
#' new_hit_type(duration = pyMTurkR::seconds(minutes = 20))
#' }
#'
new_hit_type <- function(
  title = "eviction-address-transcription",
  description = "Find and transcribe the DEFENDENT'S address from a court document pdf",
  reward = "0.15",
  duration = pyMTurkR::seconds(minutes = 10),
  keywords = "address, text, transcribe, entry, data",
  auto.approval.delay = pyMTurkR::seconds(days = 3),
  ...
) {
  assert_that(
    pyMTurkR::CheckAWSKeys(),
    msg = "AWS keys not available"
  )

  assert_that(
    is.string(title),
    is.string(description),
    is.string(reward),
    is.number(duration),
    is.string(keywords),
    is.number(auto.approval.delay)
  )

  res <- pyMTurkR::CreateHITType(
    title = title,
    description = description,
    reward = reward,
    duration = duration,
    keywords = keywords,
    auto.approval.delay = auto.approval.delay,
    ...
  )

  assert_that(
    has_names(res, c("HITTypeId", "Valid")),
    msg = "The response from pyMTurkR did not succeed or has an unexpected structure"
  )

  valid <- as.logical(res$Valid)

  assert_that(
    is.flag(valid),
    isTRUE(valid)
  )

  assert_that(
    is.string(res$HITTypeId)
  )

  return(res$HITTypeId)
}


#' @title New Case from Queue
#'
#' @param db A database connection pool created with `pool::db`
#'
#' @return A case id from the queue
#' @export
#'
#' @examples
#'
#' \dontrun{
#' new_case_from_queue()
#' }
#'
new_case_from_queue <- function(db) {
  res <- get_case_from_queue(db)

  return(res)
}
