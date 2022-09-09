#' @title New DB Pool
#' @description Creates a new connection pool to the database
#'
#' @param config The path to a `config.yml` file to be read by the {config} package using `config::get()`
#'
#' @return A database connection pool created by the {pool} package
#' @export
#'
new_db_pool <- function(config = "config.yml") {
  if(is.null(config)) {

  }

  if(!file.exists(config)) {

  }

  connection_args <- config::get("database", config = config)
  if(is.null(connection_args)) {

  }

  db <- pool::dbPool(odbc::odbc(),
                     Driver = connection_args$driver,
                     Server = connection_args$server,
                     Database = connection_args$database,
                     Port = connection_args$port,
                     Username = connection_args$uid,
                     Password = connection_args$pwd,
                     SSLmode = "verify-ca",
                     Pqopt = stringr::str_glue(
                       "{sslrootcert={{connection_args$ssl.ca}}",
                       "sslcert={{connection_args$ssl.cert}}",
                       "sslkey={{connection_args$ssl.key}}}",
                       .open = "{{",
                       .close = "}}",
                       .sep = " "
                     )
  )

  return(db)
}


#' @title New DB Connection
#' @description Creates a new connection to the database
#'
#' @param config The path to a `config.yml` file to be read by the {config} package using `config::get()`
#'
#' @return A database connection pool created with `DBI::dbConnect`
#' @export
#'
new_db_connection <- function(config = "config.yml") {
  if(is.null(config)) {

  }

  if(!file.exists(config)) {

  }

  connection_args <- config::get("database", config = config)
  if(is.null(connection_args)) {

  }

  conn <- DBI::dbConnect(
    odbc::odbc(),
    Driver = connection_args$driver,
    Server = connection_args$server,
    Database = connection_args$database,
    Port = connection_args$port,
    Username = connection_args$uid,
    Password = connection_args$pwd,
    SSLmode = "verify-ca",
    Pqopt = stringr::str_glue(
      "{sslrootcert={{connection_args$ssl.ca}}",
      "sslcert={{connection_args$ssl.cert}}",
      "sslkey={{connection_args$ssl.key}}}",
      .open = "{{",
      .close = "}}",
      .sep = " "
    )
  )

  return(conn)
}
