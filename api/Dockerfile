FROM rstudio/plumber
LABEL maintainer="brancengregory"
RUN export DEBIAN_FRONTEND=noninteractive; apt-get -y update \
  && apt-get install -y git-core \
	libpq-dev \
	libxml2-dev \
	libssl-dev \
	unixodbc-dev \
	odbc-postgresql \
	libudunits2-dev \
	libproj-dev \
	libgdal-dev
ENV R_CONFIG_ACTIVE=docker
RUN ["install2.r", "bigrquery", "cli", "config", "DBI", "dbplyr", "dbx", "dplyr", "forcats", "future", "ggmap", "ggplot2", "glue", "googleCloudRunner", "here", "httr", "leaflet", "logger", "lubridate", "odbc", "plumber", "pool", "promises", "purrr", "readr", "remotes", "RPostgres", "rvest", "sp", "stringr", "tibble", "tidyr", "tidyverse", "XML"]
RUN ["installGithub.r", "cloudyr/googleCloudStorageR@75f56fb9395ed14aecb9c39604233e72ad9a703c", "hansthompson/rusps@36090a4bf80b9ace0a669ca3bbd9d737d287f2e8", "openjusticeok/ojodb@fdfc27cd7af2585c81b64a79602957dc3d426e52"]
WORKDIR ["/workspace/"]
COPY ["./", "./"]
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb('plumber.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
CMD ["plumber.R"]
