FROM rocker/r-ver:4.2.1
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
	libfribidi-dev \
	python3-dev \
	python3-venv
ENV R_CONFIG_ACTIVE=docker
RUN ["install2.r", "remotes"]
RUN ["installGithub.r", "openjusticeok/eviction-addresses@dev"]
RUN R -s --vanilla -e "evictionAddresses::install_boto3()"
COPY /workspace/ .
CMD ["R", "-e", "getwd(); list.files(); list.files('/'); list.files('/workspace/'); evictionAddresses::run_api('config.yml', host = '0.0.0.0', port = as.numeric(Sys.getenv('PORT')))"]
