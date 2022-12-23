#' @title Run Job
#' 
#' @description Runs a refresh job
#' 
#' @param config The path to a configuration file ingested by `{config}`
#' 
#' @export
#' @returns Nothing
#' 
run_job <- function(config) {
    logger::log_threshold(logger::TRACE)

    db <- new_db_pool(config)
    withr::defer(pool::poolClose(db))

    refresh_cases(db)
    refresh_minutes(db)
    refresh_queue(db)
}