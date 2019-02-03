# Library initializations
library('shiny')
library('dplyr')
library('dbplyr')
library('DT')
library('htmlwidgets')
library('r2d3')
library('httr')
library('stringr')
library('shinyAce')
options(r2d3.theme = list(background = "rgb(0,0,0,0,0.0)"))

# Libraries requiring extra steps
conf <- config::get()
library('reticulate')
use_python(conf$python_dir, required = T)


# Globals
brb                 <- with(conf$database, DBI::dbConnect(RPostgres::Postgres(), dbname, host, port, user, password))
dag_db              <- tbl(brb, sql('select dag_id, is_paused, fileloc, owners from dag order by dag_id'))
dag_runs_db         <- tbl(brb, sql("select dag_id, state, execution_date from (select *, max(id) over (partition by dag_id) as max_id from dag_run) as x where id = max_id order by dag_id"))
task_instance_db    <- tbl(brb, sql("select recency_rank, task_id, dag_id, execution_date, state, try_number, max_tries from(select *, rank() over (partition by dag_id, task_id order by execution_date desc) as recency_rank from task_instance) as x where recency_rank = 1 order by dag_id"))

dag_dir             <- conf$dag_dir
airflow_ui_url      <- conf$airflow_ui_url
airflow_server_url  <- conf$airflow_server_url


#csrf_token          <- laminar::get_csrf_token(airflow_server_url)
#task_state_colors   <- laminar::airflow_task_state_colors()






# Functions
#---------------
get_csrf_token <- function(airflow_url){
  input_form <-
    airflow_url %>%
    paste0("/admin/queryview") %>%
    httr::GET() %>%
    httr::content() %>%
    xml2::xml_find_first('.//input[@name="_csrf_token"]') %>%
    xml2::xml_attr('value')
}

airflow_task_state_colors   <- function(){
  frame_data(
    ~state, ~color,
    "null", "lightblue",
    "scheduled", "tan",
    "queued", "gray",
    "running", "lime",
    "up_for_retry", "gold",
    "success", "green",
    "failed", "red",
    "upstream_failed", "orange"
  )
}

csrf_token          <- get_csrf_token(airflow_server_url)
task_state_colors   <- airflow_task_state_colors()


#' Circle Plot
#'
#' Function to create a d3-based horizontal circle plot
#' @param id id assigned to the html element
#' @param states data frame of the form (state, count, url).
#' @param colors data frame of the form (state, color). All states will be displayed. Row order determines display order.
#' @return r2d3 htmlwidget
circleplot <- function(id, states, colors, width = NULL, height = NULL){
  
  states_aug <-
    colors %>%
    left_join(states, "state") %>%
    tidyr::replace_na(list(count = 0))
  
  r2d3(data = states_aug, script = 'states.js', elementId = id, width = width, height = height, viewer = "browser")
  
}

# Reticulate extensions
py_to_r.pendulum.date.Date <- function(x) {lubridate::as_datetime(as.character(x))}
py_to_r.datetime.timedelta <- function(x) {as.character(x)}

py_to_r_reconvert <- function(x){
  rapply(x, function(object) {
    if (inherits(object, "python.builtin.object"))
      py_to_r(object)
    else
      object
  }, how = 'replace')
}

#py_run_string("from datetime import timedelta; x = {'a' : 1, 'b' : timedelta(minutes=5)}")
#py_to_r_reconvert(py$x)


get_af_dag_args <- function(dag_dir = config::get()$dag_dir,
                            args = c('start_date', 'schedule_interval')){
  
  pydag           <- import_from_path('dag')
  af_dags         <- pydag$list_dir_dags(dag_dir)
  af_dag_args_lst <- py_to_r_reconvert(pydag$get_dag_args(af_dags, args))
  af_dag_args     <-
    af_dag_args_lst %>%
    {data_frame(dag_id = names(.),
                schedule_interval = purrr::map_chr(., 'schedule_interval', .null =NA_character_),
                start_date = purrr::map_df(., 'start_date') %>% tidyr::gather(dag_id, start_date) %>% .$start_date
    )} 
  
  af_dag_args
}

reactivePoll2 <- function (intervalMillis, session, checkFunc)
  # Specialization of reactivePoll where checkFunc = valueFunc. Useful for databases
{
  intervalMillis <- shiny:::coerceToFunc(intervalMillis)
  rv <- reactiveValues(cookie = isolate(checkFunc()))
  observe({
    rv$cookie <- checkFunc()
    invalidateLater(intervalMillis(), session)
  })
  re <- reactive({
    rv$cookie
  }, label = NULL)
  return(re)
}

airflow_container_exec <- function(cmd) system(paste0(
  'docker exec laminar_airflow_webserver_1 sh -c "',
  cmd, '"'))



# Link template functions
dag_link <- function(dag_id)
  paste0("<a href=",airflow_ui_url,"/admin/airflow/tree?dag_id=",dag_id,">",dag_id, "</a>")

schedule_link <- function(dag_id, schedule)
  paste0('<a class = "label label-default"  href=', airflow_ui_url, '/admin/dagrun/?flt2_dag_id_equals=',dag_id,'>',schedule,'</a>')

task_url <- function(dag_id, state)
  paste0(airflow_ui_url,"/admin/taskinstance/?flt1_dag_id_equals=", dag_id, "&flt2_state_equals=", state)

glicon <- function(name, class = NULL) shiny::icon(name, class, "glyphicon")

# DAG remove modal
dagRemoveModal <- function(dag_id) {
  modalDialog(
    title = "Remove Dag",
    span("Are you sure you want to delete ", tags$b(dag_id)," now?\n\
          This option will delete the DAG file, as well as all metadata, DAG runs, etc.\n\
          This cannot be undone."),
    footer = tagList(
      modalButton("Cancel"),
      actionButton("remove_dag_ok", "OK")
    )
  )
}

# Clear history modal
clearHistoryModal <- function(dag_id) {
  modalDialog(
    title = "Clear Dag History",
    span("Are you sure you want to clear history for ", tags$b(dag_id)," now?\n\
          This option will delete all metadata, DAG runs, etc.\n\
          This cannot be undone."),
    footer = tagList(
      modalButton("Cancel"),
      actionButton("clear_dag_history_ok", "OK")
    )
  )
}


