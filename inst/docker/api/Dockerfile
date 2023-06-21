# Use the specified R base image
FROM rocker/r-ver:4

# Label the maintainer
LABEL maintainer="brancengregory"

# Update and install necessary libraries
RUN apt-get update && apt-get install -y apt-transport-https \
  git-core \
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

# Set the active R configuration
ENV R_CONFIG_ACTIVE=docker

# Install the 'pak' package and remove unnecessary files
RUN install2.r --error --skipinstalled --ncpus -1 \
	pak

# Use 'pak' to install the 'remotes' and 'here' packages and the 'eviction-addresses' package from GitHub
RUN R -q -e 'pak::pkg_install(c("remotes", "here", "openjusticeok/eviction-addresses"))'

# Set the working directory
WORKDIR /workspace/

# Copy the necessary files into the Docker image
COPY config.yml .
COPY eviction-addresses-service-account.json .
COPY shiny-apps-certs/ ./shiny-apps-certs

# Run the 'evictionAddresses::run_api()' function when the Docker container is started
CMD ["R", "-e", "evictionAddresses::run_api('config.yml', host = '0.0.0.0', port = as.numeric(Sys.getenv('PORT')))"]
