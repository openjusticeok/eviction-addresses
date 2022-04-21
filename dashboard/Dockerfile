FROM rocker/shiny
LABEL maintainer="brancengregory"
RUN export DEBIAN_FRONTEND=noninteractive; apt-get -y update \
  && apt-get install -y git-core \
	libpq-dev \
	libxml2-dev \
	libsodium-dev \
	libssl-dev \
	unixodbc-dev \
	odbc-postgresql \
	libudunits2-dev \
	libproj-dev \
	libgdal-dev
RUN ["install2.r", "bigrquery", "config", "DBI", "dbx", "dplyr", "forcats", "ggplot2", "glue", "googleCloudRunner", "here", "httr", "jsonlite", "leaflet", "lubridate", "odbc", "pool", "purrr", "readr", "remotes", "RPostgres", "rvest", "shiny", "shinydashboard", "shinyjs", "shinyauthr", "sp", "stringr", "tibble", "tidyr", "tidyverse"]
RUN ["installGithub.r", "openjusticeok/ojodb@c5972c6ad36c6ff66851cb920cc8c3a422719475"]
WORKDIR /payload/
COPY ["./", "/srv/shiny-server/"]
USER shiny
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
