FROM rocker/r-ver:4.2

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install \
        python3-pip \
        libgit2-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libxt-dev \
        libpq-dev \
    && python3 -m pip --no-cache-dir install radian \
    && install2.r --error --skipinstalled --ncpus -1 \
        here \
        languageserver \
        httpgd \
        markdown

RUN R -e "library(here)"
RUN R -e "library(languageserver)"
