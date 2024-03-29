% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/db.R
\name{new_db_pool}
\alias{new_db_pool}
\title{New DB Pool}
\usage{
new_db_pool(config = "config.yml")
}
\arguments{
\item{config}{The path to a \code{config.yml} file to be read by the {config} package using \code{config::get()}}
}
\value{
A database connection pool created by the {pool} package
}
\description{
Creates a new connection pool to the database
}
