#' The laminar package
#'
#' @docType package
#' @name laminar
#' @import dplyr
NULL

#' Launch Laminar
#'
#' Launch the Laminar application
#' @param appDir the application to run. Defaults to application within the installed laminar package.
#' @param ... any other arguments passed to shiny::runApp
launch_application <- function(appDir = system.file("laminar_app", package = 'laminar'), ...)
{
  shiny::runApp(appDir = appDir,
                ...)
}
