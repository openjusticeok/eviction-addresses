FROM rocker/r-ver:4.2.2
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
	libsodium-dev
ENV R_CONFIG_ACTIVE=docker
RUN ["install2.r", "remotes", "here"]
RUN ["installGithub.r", "openjusticeok/eviction-addresses"]
WORKDIR /workspace/
COPY config.yml .
COPY eviction-addresses-service-account.json .
COPY shiny-apps-certs/ ./shiny-apps-certs
CMD ["R", "-e", "evictionAddresses::run_api('config.yml', host = '0.0.0.0', port = as.numeric(Sys.getenv('PORT')))"]
