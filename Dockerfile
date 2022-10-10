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
	libfribidi-dev \
	python3.8-venv
ENV R_CONFIG_ACTIVE=docker
RUN ["install2.r", "renv"]
RUN ["installGithub.r", "openjusticeok/eviction-addresses@dev"]
WORKDIR ["/workspace/"]
COPY ["./", "./"]
RUN R -s --vanilla -e "evictionAddresses::install_boto3()"
RUN R -s --vanilla -e "evictionAddresses::run_api('config.yml')"
