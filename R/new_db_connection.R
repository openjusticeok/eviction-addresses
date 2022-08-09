#' @title New DB Connection
#' @description Creates a new connection to the database
#'
#' @param connection_args A list of arguments to be used in the {pool} configuration. This should be created by the {config} package using `config::get()` and a `config.yml` file
#'
#' @return A database connection pool created by the {pool} package
#' @export
#'
new_db_connection <- function(connection_args) {
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
}
