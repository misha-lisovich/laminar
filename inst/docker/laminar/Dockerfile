FROM rocker/shiny

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  libxml2-dev \
  libcairo2-dev \
  libsqlite3-dev \
  libmariadbd-dev \
  libmariadb-client-lgpl-dev \
  libpq-dev \
  libssl-dev \
  libcurl4-openssl-dev \
  libssh2-1-dev \
  unixodbc-dev \
  && R -e "install.packages(c( \
    'devtools', \
    'config', \
    'tidyverse', \
    'dplyr', \
    'dbplyr', \
    'RPostgres', \
    'DT', \
    'reticulate', \
    'htmlwidgets', \
    'httr', \
    'r2d3', \
    'shinyAce', \
    'future', \
    'shinyjs', \
    'xml2'))"

RUN apt-get install -y libpython3-dev python3-pip

ENV SLUGIFY_USES_TEXT_UNIDECODE=yes
RUN pip3 install apache-airflow

COPY config/.bash_profile /home/shiny/.bash_profile

#RUN R -e "devtools::install('./../../../', dependencies = FALSE)" #install laminar package


