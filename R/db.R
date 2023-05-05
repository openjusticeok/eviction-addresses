#' @title New DB Pool
#' @description Creates a new connection pool to the database
#'
#' @param config The path to a `config.yml` file to be read by the {config} package using `config::get()`
#'
#' @returns A database connection pool created by the {pool} package
#' @export
#'
new_db_pool <- function(config = "config.yml") {
  if(is.null(config)) {

  }

  if(!file.exists(config)) {

  }

  connection_args <- config::get("database", file = config)
  if(is.null(connection_args)) {

  }

  db <- pool::dbPool(
    drv = RPostgres::Postgres(),
    dbname = connection_args$database,
    host = connection_args$server,
    port = connection_args$port,
    user = connection_args$uid,
    password = connection_args$pwd,
    sslmode = "verify-ca",
    sslrootcert = connection_args$ssl.ca,
    sslcert = connection_args$ssl.cert,
    sslkey = connection_args$ssl.key,
    bigint = "integer"
  )

  return(db)
}


#' @title New DB Connection
#' @description Creates a new connection to the database
#'
#' @param config The path to a `config.yml` file to be read by the {config} package using `config::get()`
#'
#' @returns A database connection pool created with `DBI::dbConnect`
#'
new_db_connection <- function(config = "config.yml") {
  if(is.null(config)) {

  }

  if(!file.exists(config)) {

  }

  connection_args <- config::get("database", file = config)
  if(is.null(connection_args)) {

  }

  conn <- DBI::dbConnect(
    drv = RPostgres::Postgres(),
    dbname = connection_args$database,
    host = connection_args$server,
    port = connection_args$port,
    user = connection_args$uid,
    password = connection_args$pwd,
    sslmode = "verify-ca",
    sslrootcert = connection_args$ssl.ca,
    sslcert = connection_args$ssl.cert,
    sslkey = connection_args$ssl.key,
    bigint = "integer"
  )

  return(conn)
}
