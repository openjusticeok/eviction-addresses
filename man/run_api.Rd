% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/run_api.R
\name{run_api}
\alias{run_api}
\title{Run API}
\usage{
run_api(config, ..., .background = FALSE)
}
\arguments{
\item{config}{The path to a configuration file ingested by \code{{config}}}

\item{...}{Additional arguments passed to \code{plumber::pr_run}, e.g. port = 8080}

\item{.background}{Whether to start the API in a background process}
}
\value{
Nothing
}
\description{
Starts the eviction address api
}
