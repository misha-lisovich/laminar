# laminar

Laminar aims to make for a smoother Apache Airflow admin experience by providing a Shiny-based UI which 
1) shows a real-time, globally-consistent state for all Airflow DAGs and tasks, 2) allows for simpler CRUD operations by
taking care of the complex interrelationships between DAG Python files, DAG objects, Database metadata, Scheduler process memory 
and Webserver process memory to present a single logical DAG entity with straigtforward create/edit/delete mechanics.

## Installation

Laminar is only available on Github. You can install it with: 

``` r
require('devtools')
devtools::install_github("mul118/laminar")
```

## Example

To run the app, type the following:

``` r
laminar::launch_application()
```


## TODO
1. Implement HTTP functionality for Delete DAG and Clear History buttons
2. Support full complement of Airflow example dags by e.g., properly dealing with subdags


