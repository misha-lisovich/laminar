navbarPage(
  id = 'airflow_nav',
  title = div(img(src='pin_100.png', style = 'float: left; width: 35px; margin-top: -7px;'), "Airflow"),
  windowTitle = 'Laminar',
  inverse = TRUE,
  collapsible = TRUE,
  theme = "bootstrap-theme.css",
  navbarMenu(
    "DAGs",
    tabPanel("Summary",
             shinyjs::useShinyjs(),
             DT::dataTableOutput('dag'),
             span(
               height = '20px',
               shinyjs::hidden(
                 span(id = "dag_actions_panel",
                      actionButton("trigger_dag", "Trigger", icon = glicon('play-circle')),
                      actionButton("pause_dag", "Pause/Unpause", icon = glicon('pause')),
                      actionButton("edit_dag", "Edit", icon = glicon('edit')),
                      actionButton("clear_dag_history", "Clear History", icon = glicon('erase')),
                      actionButton("remove_dag", "Remove", icon = glicon('remove'))
             ))),
             r2d3::d3Output('d3deps', "1px", "1")
    ),
    tabPanel("DAG Editor",
             fluidRow(
               column(3, selectizeInput("dag_to_edit", "Select Dag", NULL)),
               column(3, textInput("dag_filename", "Dag File Name", placeholder = "Filename to save DAG in"))
             ),
             shinyAce::aceEditor("dag_editor", "", "python", wordWrap = TRUE),
             span(
               actionButton("save_dag_edits", "Save Changes", icon = glicon('floppy-disk')),
               actionButton("cancel_dag_edits", "Cancel")
             )
    )
  ),
  navbarMenu("Admin",
             tabPanel("Pools"),
             tabPanel("Configuration"),
             tabPanel("Users"),
             tabPanel("Variables"),
             tabPanel("Xcoms")),
  navbarMenu("About",
             tabPanel("Version"))
)
