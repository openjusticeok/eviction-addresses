#' @title Auth MTurk
#'
#' @param config A file path to a config.yml
#'
#' @return A logical/boolean representing whether we successfully connected to MTurk
#' @export
#'
#' @examples
#'
#' auth_mturk()
#' auth_mturk(config = "config.yml")
#'
auth_mturk <- function(config = NULL) {
  if(!is.null(config)) {
    logger::log_debug("Config file supplied; using config variables")

    aws_config <- config::get("aws", file = config)

    env_set <- Sys.setenv(
      AWS_ACCESS_KEY_ID = aws_config$key.id,
      AWS_SECRET_ACCESS_KEY = aws_config$key.secret
    )

    if(!all(env_set)) {
      logger::log_error("Failed to set environment variables")
      return(F)
    }
  } else {
    logger::log_debug("No config file supplied; using env variables")
  }

  check_auth <- pyMTurkR::CheckAWSKeys()
  if(check_auth) {
    logger::log_success("pyMTurkR found auth keys")
    return(invisible(T))
  }

  logger::log_error("pyMTurkR didn't find auth keys")
  return(F)
}


#' @title Set HIT Type
#'
#' @param title
#' @param description
#' @param reward
#' @param duration
#' @param keywords
#' @param auto.approval.delay
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
set_hit_type <- function(
  title = "eviction-address-transcription",
  description = "Find and transcribe the DEFENDENT'S address from a court document pdf",
  reward = "0.15",
  duration = pyMTurkR::seconds(minutes = 10),
  keywords = "address, text, transcribe, entry, data",
  auto.approval.delay = pyMTurkR::seconds(days = 3),
  ...
) {
  hit_type <- pyMTurkR::CreateHITType(
    title = title,
    description = description,
    reward = reward,
    duration = duration,
    keywords = keywords,
    auto.approval.delay = auto.approval.delay,
    ...
  )

  return(hit_type)
}



#' @title Render HIT Layout
#'
#' @param layout A file path to an XML layout
#'
#' @return A character string containing an XML layout
#' @export
#'
render_hit_layout <- function(layout = NULL) {
  if(is.null(layout)) {
    logger::log_debug("No layout file supplied; using layout provided by package")
    layout <- system.file("mturk/layout.xml", package = "evictionAddresses")
  }

  if(!file.exists(layout)) {
    logger::log_error("No file found at: {layout}")
    stop("Could not render layout: No file found at: {layout}")
  }

  raw_layout <- readr::read_file(layout)
}


#' Title
#'
#' @return
#' @export
#'
#' @examples
new_hit_from_case <- function() {
  hit_table <- DBI::Id(schema = "eviction_addresses", table = "hit")

}


#' Title
#'
#' @return
#' @export
#'
#' @examples
check_all_hits <- function() {
  reviewable_hits <- pyMTurkR::GetReviewableHITs() |>
    as_tibble()

  pyMTurkR::ListAssignmentsForHIT(get.answers = T)
}


#' Title
#'
#' @return
#' @export
#'
#' @examples
compare_hit_assignments <- function(hit = NULL) {
  if(is.null(hit) || !is.character(hit))

  hit_assignments <- pyMTurkR::GetAssignments(hit = hit, get.answers = T)
}


#' Title
#'
#' @return
#' @export
#'
#' @examples
finalize_hit <- function() {

}
