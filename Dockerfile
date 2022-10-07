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
	libgdal-dev \
	libmagick++-dev \
	libharfbuzz-dev \
	libfribidi-dev
ENV R_CONFIG_ACTIVE=default
RUN ["install2.r", "renv"]
WORKDIR ["/workspace/"]
COPY ["./", "./"]
RUN R -s --vanilla -e "renv::restore();"
