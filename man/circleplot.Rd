% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/circleplot.R
\name{circleplot}
\alias{circleplot}
\title{Circle Plot}
\usage{
circleplot(id, states, colors, width = NULL, height = NULL)
}
\arguments{
\item{id}{id assigned to the html element}

\item{states}{data frame of the form (state, count, url).}

\item{colors}{data frame of the form (state, color). All states will be displayed. Row order determines display order.}

\item{width}{Desired width for output widget.}

\item{height}{Desired height for output widget.}
}
\value{
r2d3 htmlwidget
}
\description{
Function to create a d3-based horizontal circle plot
}
\examples{
{
 states <- data.frame(state = airflow_task_state_colors()$state, count = 1:8, url = 'www.https://d3js.org/')
 circleplot('af_plot', states, airflow_task_state_colors())}
}
