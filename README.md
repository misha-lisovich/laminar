# laminar <a href='https://github.com/misha-lisovich/laminar'><img src="inst/figures/laminar.png" align="right" height="139" width="139"></a>

[![Travis build status](https://travis-ci.org/misha-lisovich/laminar.svg?branch=master)](https://travis-ci.org/misha-lisovich/laminar)

**NOTE: this package is under active development, and should be considered pre-alpha.**

Laminar aims to make for a smoother Apache Airflow admin experience by providing a Shiny-based UI which: 

1. Provides a real-time, globally-consistent state for all Airflow DAGs and tasks
2. Allows for simpler CRUD operations by taking care of the complex interrelationships between DAG Python files, DAG objects, Database metadata, Scheduler process memory and Webserver process memory to present a single logical DAG entity with straigtforward create/edit/delete mechanics.

## Installation

Laminar is only available on Github. You can install it with: 

``` r
require('devtools')
devtools::install_github("misha-lisovich/laminar")
```

Laminar requires a running Airflow instance backed by a Postgres database (to be generalized). The best way to experience it is by building & running the installed Docker/Docker-Compose files.


## Docker Image

Clone the laminar directory to your computer. 

To build the laminar docker image, navigate to the root laminar directory and type:

``` bash
docker build -t laminar -f inst/docker/laminar/Dockerfile .
```

Then execute:

``` bash
docker-compose up -f inst/docker/docker-compose.yaml up -d
```

This will bring up linked containers containing:

* **Apache Airflow** from [puckel/docker-airflow](https://hub.docker.com/r/puckel/docker-airflow/)
* **Postgres** database [dockerhub/postgres](https://hub.docker.com/_/postgres)
* **Laminar** image derived from [rocker/shiny](https://hub.docker.com/r/rocker/shiny/)


## Custom Settings

Laminar uses Rstudio's [config](https://github.com/rstudio/config) package to store & accesss per-environment settings. To customize settings modify the config.yaml file located in inst/laminar_app, then reinstall/rebuild as needed.


## TODO
1. Implement HTTP functionality for Delete DAG and Clear History buttons
2. Support full complement of Airflow example dags by e.g., properly dealing with subdags


