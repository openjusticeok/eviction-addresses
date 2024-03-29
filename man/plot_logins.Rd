% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/report.R
\name{plot_logins}
\alias{plot_logins}
\title{Plot Logins}
\usage{
plot_logins(
  db,
  users,
  start = lubridate::ymd("2022-12-12"),
  end = lubridate::today(),
  .silent = FALSE
)
}
\arguments{
\item{db}{A database connection pool created with \code{pool::dbPool}}

\item{users}{A vector of users to plot}

\item{start}{The start date}

\item{end}{The end date}
}
\value{
A ggplot object
}
\description{
Plots the number of logins per day
}
\examples{
\dontrun{
plot_logins(db, c("test", "test2"), lubridate::ymd("2022-12-12"), lubridate::today())
}

}
