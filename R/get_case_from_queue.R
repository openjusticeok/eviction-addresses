#' @title Get Case from Queue
#'
#' @param db A database connection pool created with `pool::dbPool`
#'
#' @return A case id
#' @export
#'
get_case_from_queue <- function(db) {

  pool::poolWithTransaction(db, func = function(conn) {
    case <- DBI::dbGetQuery(
      conn,
      dbplyr::sql('SELECT q."case" FROM eviction_addresses.queue q LEFT JOIN eviction_addresses."case" c ON q."case" = c."id" LEFT JOIN public."case" pc ON q."case" = pc.id WHERE "success" IS NOT TRUE AND "working" IS NOT TRUE ORDER BY attempts ASC, pc.status DESC, c.date_filed DESC LIMIT 1 FOR UPDATE OF q SKIP LOCKED;')
    )
    query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET working = TRUE WHERE "case" = {case}', .con = conn)
    res <- DBI::dbExecute(conn, query)

    case_id <- case$case[1]

    return(case_id)
  })

}
