#' @title Get Documents by Case
#'
#' @param id The id of the case for which to return documents
#'
#' @return A data.frame of documents
#' @export
#'
get_documents_by_case <- function(id) {
  query <- glue::glue_sql('SELECT * FROM "eviction_addresses"."document" t WHERE t."case" = {id};', .con = db)

  res <- DBI::dbGetQuery(db, query)

  return(res)
}
