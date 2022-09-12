% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/run_dashboard.R
\name{run_dashboard}
\alias{run_dashboard}
\title{Run Dashboard}
\usage{
run_dashboard(config, db, ...)
}
\arguments{
\item{config}{The path to a config.yml file}

\item{db}{A database connection pool created with \code{pool::dbPool}}

\item{...}{Additional arguments passed to \code{shiny::shinyApp}}
}
\description{
Runs the eviction address entry dashboard
}