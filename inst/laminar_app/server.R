# Template functions
#-------------------

# Link templates
dag_link <- function(dag_id)
  paste0("<a href=",airflow_ui_url,"/admin/airflow/tree?dag_id=",dag_id,">",dag_id, "</a>")

schedule_link <- function(dag_id, schedule)
  paste0('<a class = "label label-default"  href=', airflow_ui_url, '/admin/dagrun/?flt2_dag_id_equals=',dag_id,'>',schedule,'</a>')

task_url <- function(dag_id, state)
  paste0(airflow_ui_url,"/admin/taskinstance/?flt1_dag_id_equals=", dag_id, "&flt2_state_equals=", state)

airflow_container_exec <- function(cmd) system(paste0(
  'docker exec laminar_airflow_webserver_1 sh -c "',
  cmd, '"'))

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

# Server Logic
#-------------
server <- function(input, output, session) {


  dag_args <- reactivePoll(
    1000,
    session,
    checkFunc = function() fs::file_info(dag_dir)$modification_time,
    valueFunc = get_af_dag_args
  )

  dag <- reactivePoll2(
    4000,
    session,
    checkFunc = function() collect(dag_db)
  )

  dag_runs <- reactivePoll2(
    5000,
    session,
    checkFunc = function() collect(dag_runs_db)
  )

  task_instance <- reactivePoll2(
    3000,
    session,
    checkFunc = function() collect(task_instance_db)
  )


  observe({
    if(is.null(input$dag_rows_selected)){
      shinyjs::hide('dag_actions_panel')
    }else{
      shinyjs::show('dag_actions_panel')
    }
  })

  observeEvent(dag_args, {
    dag_filenames <- dir(dag_dir, pattern = '[.]py$')
    edit_dag_filename <- input$dag_to_edit
    updateSelectizeInput(session, "dag_to_edit", "Select Dag", choices = dag_filenames, selected = edit_dag_filename)
  })

  observeEvent(input$dag_to_edit, {
    edit_dag_filename <- input$dag_to_edit
    updateTextInput(session, "dag_filename", "Dag File Name", edit_dag_filename)
    dag_text <- ifelse(edit_dag_filename == "", "", readr::read_file(paste0(dag_dir, "/", edit_dag_filename)))
    shinyAce::updateAceEditor(session, "dag_editor", dag_text, mode = "python", wordWrap = TRUE)
  })

  observeEvent(input$cancel_dag_edits,{
    updateNavbarPage(session, "airflow_nav", "Summary")
  })

  observeEvent(input$save_dag_edits,{
    filepath <- paste0(dag_dir, "/", input$dag_filename)
    readr::write_file(input$dag_editor, filepath)

    # Need to handle the following conditions:
    # 1. Conflicting dag name (same dag, different file)
    # 2. Broken dag produced
    # 3. One of the immutable parameters changed. History would be deleted

  })



  task_plots <- reactive({
    task_instance() %>%
      group_by(dag_id, state) %>%
      summarise(count = n()) %>%
      tidyr::replace_na(list(state = "null")) %>%
      group_by(dag_id) %>%
      summarise(
        tasks =
          laminar::circleplot(paste0("task_", dag_id[1]), data_frame(state, count, url = task_url(dag_id, state)), task_state_colors, "240px", "37") %>%
          htmltools::as.tags() %>%
          as.character %>%
          HTML
      ) %>%
      ungroup
  })


  dag_disp <- reactive({
    dag() %>%
      full_join(dag_args(), "dag_id") %>%
      left_join(dag_runs(), "dag_id") %>%
      left_join(task_plots(), "dag_id") %>%
      mutate(dag_id_disp = dag_link(dag_id),
             schedule = schedule_link(dag_id, tidyr::replace_na(schedule_interval, "None")),
             status = ifelse(is_paused, "Paused", "Active"),
             state = str_to_title(state)) %>%
      select(dag_id = dag_id_disp, status, schedule, tasks, owners, state, last_run = execution_date, start_date)
  })

  # Handle Actions

  # Trigger Dag
  observeEvent(input$trigger_dag, {
    dag_id <- dag()$dag_id[input$dag_rows_selected]

    # Trigger via admin api
    airflow_server_url %>%
      modify_url(
        path =  "admin/airflow/trigger",
        query = list(dag_id = dag_id)
      ) %>%
      GET

    # # Invoke trigger command
    # toggle_dag_cmd <- paste0('airflow trigger_dag ', dag_id)
    # future(airflow_container_exec(toggle_dag_cmd))

    showNotification(span("Triggered ", tags$b(dag_id), ". It should start momentarily."), type = "message")

  })

  # Dag edit
  observeEvent(input$edit_dag,{
    dag_id <- dag()$dag_id[input$dag_rows_selected]
    dag_filenames <- dir(dag_dir, pattern = '[.]py$')
    edit_dag_filename <- paste0(dag_id, ".py")
    updateSelectizeInput(session, "dag_to_edit", "Select Dag", choices = dag_filenames, selected = edit_dag_filename)
    updateTextInput(session, "dag_filename", "Dag File Name", edit_dag_filename)
    updateNavbarPage(session, "airflow_nav", "DAG Editor")
  })


  # Dag Pause
  observeEvent(input$pause_dag, {
    dag_ind <- input$dag_rows_selected
    dag_id <- dag()$dag_id[dag_ind]
    dag_status <- dag()$is_paused[dag_ind]

    new_status <- ifelse(dag_status, "true", "false") # pause = false, unpause = true
    airflow_server_url %>%
      modify_url(
        path = "admin/airflow/paused",
        query = list(is_paused = new_status, dag_id = dag_id)
      ) %>%
      POST(body = list(csrf_token = csrf_token))


    # # Invoke toggle command via api
    # new_status <- ifelse(dag_status, "unpause", "pause")
    # toggle_dag_cmd <- paste0('airflow ', new_status, ' ', dag_id)
    # future(airflow_container_exec(toggle_dag_cmd))

    showNotification(span(str_to_title(new_status)," command submitted for ", tags$b(dag_id), ". Please wait for Airflow to update."), type = "message")
  })

  # Remove dag dialog
  observeEvent(input$remove_dag, {
    dag_id <- dag()$dag_id[input$dag_rows_selected]
    showModal(dagRemoveModal(dag_id))
  })

  # Remove dag
  observeEvent(input$remove_dag_ok, {
    dag_id <- dag()$dag_id[input$dag_rows_selected]
    message(paste0('Trigger removal of ', dag_id))
    removeModal()

    # Invoke remove
    delete_dag_cmd <- paste0('rm dags/', dag_id, '.py && airflow delete_dag ', dag_id)
    message(delete_dag_cmd)
    #future(airflow_container_exec(delete_dag_cmd))
    showNotification(span("Deleting dag file & metadata for ", tags$b(dag_id),"."), type = "message")

  })

  # Clear dag history dialog
  observeEvent(input$clear_dag_history, {
    dag_id <- dag()$dag_id[input$dag_rows_selected]
    showModal(clearHistoryModal(dag_id))
  })

  # Clear dag history
  observeEvent(input$clear_dag_history_ok, {
    dag_id <- dag()$dag_id[input$dag_rows_selected]
    message(paste0('Trigger clear history for ', dag_id))
    removeModal()

    # Invoke clear history
    toggle_dag_cmd <- paste0('airflow clear -c ', dag_id)
    #future(airflow_container_exec(toggle_dag_cmd))
    showNotification(span("Clearing history for ", tags$b(dag_id), ". Please wait for Airflow to update."), type = "message")
  })


  # Main dag status table
  output$dag <- DT::renderDataTable({
    dag_disp_df <- isolate(dag_disp())
    DT::datatable(
      data = dag_disp_df,
      selection = 'single',
      escape = FALSE,
      #rownames = FALSE,
      options = list(
        fnDrawCallback = htmlwidgets::JS('function(){ HTMLWidgets.staticRender();}'))
    ) %>%
      DT::formatStyle('status', color = DT::styleEqual(c('Paused', 'Active'), c('gray', 'green'))) %>%
      DT::formatStyle('state', color = DT::styleEqual(c('Running', 'Success', 'Failed'), c('green', 'green', 'red'))) %>%
      DT::formatDate(c('last_run', 'start_date'), method = "toLocaleString")
  })

  dag_proxy <- DT::dataTableProxy('dag')

  observe({
    DT::replaceData(dag_proxy, dag_disp(), resetPaging = FALSE, clearSelection = FALSE)
  })

  # Dummy render to initialize r2d3 deps. Needs rework
  output$d3deps <- r2d3::renderD3({
    r2d3::r2d3(data = c (0.3, 0.6, 0.8, 0.95, 0.40, 0.20),
         script = system.file("examples/barchart.js", package = "r2d3")
    )
  })

}
