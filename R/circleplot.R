#' Circle Plot
#'
#' Function to create a d3-based horizontal circle plot
#' @param id id assigned to the html element
#' @param states data frame of the form (state, count, url).
#' @param colors data frame of the form (state, color). All states will be displayed. Row order determines display order.
#' @inheritParams r2d3::r2d3
#' @examples {
#'  states <- data.frame(state = airflow_task_state_colors()$state, count = 1:8, url = 'www.https://d3js.org/')
#'  circleplot('af_plot', states, airflow_task_state_colors())}
#' @return r2d3 htmlwidget
#' @export
circleplot <- function(id, states, colors, width = NULL, height = NULL){

  options(r2d3.theme = list(background = "rgb(0,0,0,0,0.0)"))
  script <- paste0(system.file(package = 'laminar'), '/circleplot.js')

  states_aug <-
    colors %>%
    left_join(states, "state") %>%
    tidyr::replace_na(list(count = 0))

  r2d3::r2d3(data = states_aug, script = script, elementId = id, width = width, height = height)

}


#' Airflow task-state colors
#'
#' Convenience function to get state-color mappings for Airflow
#' @return data frame of the form (state, color)
#' @export
airflow_task_state_colors   <- function(){
  dplyr::frame_data(
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
