#' @title Get Documents by Case
#'
#' @param db A database connection pool created with `pool::dbPool`
#' @param id The id of the case for which to return documents
#'
#' @return A data.frame of documents
#'
get_documents_by_case <- function(db, id) {
  query <- glue::glue_sql('SELECT * FROM "eviction_addresses"."document" t WHERE t."case" = {id};', .con = db)

  res <- DBI::dbGetQuery(db, query)

  return(res)
}
