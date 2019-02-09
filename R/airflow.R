#' Get Airflow csrf token
#'
#' Get csrf token by scraping Airflow's queryview page
#' @param airflow_url base url for airflow instance
#' @return csrf token string
#' @export
get_csrf_token <- function(airflow_url){
  airflow_url %>%
    paste0("/admin/queryview") %>%
    httr::GET() %>%
    httr::content() %>%
    xml2::xml_find_first('.//input[@name="_csrf_token"]') %>%
    xml2::xml_attr('value')
}


# date conversion
py_to_r.pendulum.date.Date <- function(x) {lubridate::as_datetime(as.character(x))}

# timedelta conversion
py_to_r.datetime.timedelta <- function(x) {as.character(x)}

# recursively (re)convert list of reticulate into R equivalents
py_to_r_reconvert <- function(x){
  rapply(x, function(object) {
    if (inherits(object, "python.builtin.object"))
      reticulate::py_to_r(object)
    else
      object
  }, how = 'replace')
}


#' Get airflow dag args
#'
#' Get specified args (attributes) from all Airflow dags contained in dag_dir
#' @param dag_dir airflow dag directory
#' @param args attributes to extract. NOTE: currently only extracts start_date and schedule_interval - needs generalization.
#' @return data frame of the form (dag_id, dag_args)
#' @export
get_af_dag_args <- function(dag_dir = config::get()$dag_dir,
                            args = c('start_date', 'schedule_interval')){

  dag_filepath    <- system.file(package = 'laminar')
  pydag           <- reticulate::import_from_path('dag', path = dag_filepath)
  af_dags         <- pydag$list_dir_dags(dag_dir)
  af_dag_args_lst <- py_to_r_reconvert(pydag$get_dag_args(af_dags, args))
  af_dag_args     <-
    af_dag_args_lst %>%
    {data_frame(dag_id = names(.),
                schedule_interval = purrr::map_chr(., 'schedule_interval', .null = NA_character_),
                start_date = purrr::map_df(., 'start_date') %>% tidyr::gather(dag_id, start_date) %>% .$start_date
    )}

  af_dag_args
}
