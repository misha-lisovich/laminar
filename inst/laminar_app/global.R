# Library initializations
library('shiny')
library('dplyr')
library('htmlwidgets')
library('r2d3')
library('httr')
library('stringr')
options(r2d3.theme = list(background = "rgb(0,0,0,0,0.0)"))

# Libraries requiring extra steps
conf <- config::get()
library('reticulate')
use_python(conf$python_dir, required = T)

library('laminar')

# Globals
brb                 <- with(conf$database, DBI::dbConnect(RPostgres::Postgres(), dbname, host, port, user, password))
dag_db              <- tbl(brb, sql('select dag_id, is_paused, fileloc, owners from dag order by dag_id'))
dag_runs_db         <- tbl(brb, sql("select dag_id, state, execution_date from (select *, max(id) over (partition by dag_id) as max_id from dag_run) as x where id = max_id order by dag_id"))
task_instance_db    <- tbl(brb, sql("select recency_rank, task_id, dag_id, execution_date, state, try_number, max_tries from(select *, rank() over (partition by dag_id, task_id order by execution_date desc) as recency_rank from task_instance) as x where recency_rank = 1 order by dag_id"))

dag_dir             <- conf$dag_dir
airflow_ui_url      <- conf$airflow_ui_url
airflow_server_url  <- conf$airflow_server_url

csrf_token          <- laminar::get_csrf_token(airflow_server_url)
task_state_colors   <- laminar::airflow_task_state_colors()
