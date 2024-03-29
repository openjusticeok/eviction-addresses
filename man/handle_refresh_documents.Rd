% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/handle_refresh.R
\name{handle_refresh_documents}
\alias{handle_refresh_documents}
\title{Handle API Refresh Documents}
\usage{
handle_refresh_documents(config)
}
\arguments{
\item{config}{The path to a configuration file ingested by \code{{config}}}
}
\description{
Plumber handler for endpoint \verb{/refresh/documents/<n>}
}
\details{
This endpoint refreshes documents in the eviction_addresses schema. It then
updates the work queue based on what it finds.
}
