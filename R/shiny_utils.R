#' Reactive Polling
#'
#' Specialization of shiny::reactivePoll where checkFunc is reused as valueFunc.
#' Useful making database table sources reactive without querying twice.
#' @examples
#'  \dontrun{cars <- reactivePoll(1000, session, collect(tbl(db, sql('select * from cars'))) )}
#' @inheritParams shiny::reactivePoll
#' @export
reactivePoll2 <- function (intervalMillis, session, checkFunc)
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

#' Glyph Icon
#'
#' Specialization of shiny::icon using glyphicon library
#' @inheritParams shiny::icon
#' @export
glicon <- function(name, class = NULL) shiny::icon(name, class, "glyphicon")
