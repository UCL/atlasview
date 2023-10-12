#' @importFrom rlang .data
atlasview_server <-  function(input, output, session) {

  atlasview_data <- get_atlasview_data()

  # User must be authenticated to access the app. Check for res_auth$user
  res_auth <- shinymanager::secure_server(
    check_credentials = shinymanager::check_credentials(get_credentials())
  )

  # Once user has been authenticated, create the JWT and XSRF tokens required
  # to automatically login to Remark comment engine
  observeEvent(
    res_auth$user,
    {
      req(res_auth$user)
      user <- reactiveValuesToList(res_auth)
      if (is.null(cookies::get_cookie("JWT"))) {
        # TODO: we need to remove these cookies on visit to the login screen
        # (when running shiny app in rstudio - already works when deployed to prod)
        jwt <- get_jwt_token(user$user)
        cookies::set_cookie("JWT", jwt$JWT)
        cookies::set_cookie("XSRF-TOKEN", jwt$XSRF)
      }
    }
  )

  # Application accepts a `/?disease=<specialty_code>$<phecode>` query parameter
  diseaseFromURL <- reactiveValues(specialty = NULL, disease = NULL)

  # Extract the `disease` parameter from URL, if it exists
  observeEvent(
    session$clientData$url_search,
    {
      query <- parse_url(session$clientData$url_search)
      req(query)
      diseaseFromURL$specialty <- query$specialty
      diseaseFromURL$disease <- query$disease
    }
  )

  # If disease has been picked up from URL, assume user wants to see the comments page
  observe({
    req(diseaseFromURL$disease)
    updateTabsetPanel(session, "panels", selected = "comments")
  })

  # Populate the specialties drop-down with those items user is allowed to view
  # specified in `users.csv`
  observeEvent(
    res_auth$user,
    {
      req(res_auth$user)
      users_specialties <- dplyr::filter(
        atlasview_data$specialties,
        stringr::str_detect(.data$code, res_auth$specialty_codes)
      )

      updateSelectizeInput(
        session = getDefaultReactiveDomain(),
        inputId = "select_specialty",
        choices = split(users_specialties$code, users_specialties$specialty),
        selected = diseaseFromURL$specialty,
        options = list(
          placeholder = "Please select a specialty",
          onInitialize = I('function() { this.setValue(""); }')
        )
      )
    }
  )

  # When specialty has been selected, update the list of index diseases
  observeEvent(
    input$select_specialty,
    {
      req(res_auth$user)

      # Set the selected disease from the URL, if it has been provided
      choices <- get_index_diseases(atlasview_data$index_diseases, input$select_specialty)
      options <- list(placeholder = "")
      
      # if any diseases found
      if (length(choices)) {
        options <- list(
          placeholder = "please select an index disease",
          oninitialize = I('function() { this.setvalue(""); }')
        )
      }

      updateSelectizeInput(
        session = getDefaultReactiveDomain(),
        inputId = "select_index_disease",
        choices = choices,
        selected = diseaseFromURL$disease,
        options = options
      )
    }
  )

  output$nrows <- reactive({
    req(input$select_index_disease)
    TRUE
  })

  outputOptions(output, "nrows", suspendWhenHidden = FALSE)

  # Update the page title (used in both header and window title) when the selection of specialty/disease changes
  pageTitle <- eventReactive(
    list(input$select_specialty, input$select_index_disease),
    {
      req(res_auth$user)
      generate_pagetitle(atlasview_data, input$select_specialty, input$select_index_disease)
    }
  )

  # Update the page header
  output$pageTitle <- renderText({
    pageTitle()
  })

  # Update the window title
  observeEvent(
    pageTitle(),
    {
      shinytitle::change_window_title(session, pageTitle())
    }
  )

  # CATERPILLAR TAB ##########################################################

  observeEvent(
    list(input$select_specialty, input$select_index_disease),
    {
      req(res_auth$user, input$select_specialty)
      cooccurring_diseases <- dplyr::filter(
        atlasview_data$MM_res,
        .data$specialty_code == input$select_specialty,
        .data$phecode_index_dis == input$select_index_disease
      )
      cooccurring_diseases <- dplyr::select(cooccurring_diseases, .data$specialty_cooccurring_dis)
      cooccurring_diseases <- dplyr::distinct(cooccurring_diseases)
      cooccurring_diseases <- dplyr::arrange(cooccurring_diseases, .data$specialty_cooccurring_dis)
      cooccurring_diseases <- dplyr::pull(cooccurring_diseases)

      updateSelectInput(session, "filter", choices = cooccurring_diseases, selected = cooccurring_diseases)
    }
  )

  caterpillarFilter <- debounce(reactive(input$filter), 1000)

  MM_res_spe_phe_selected <- reactive({
    req(res_auth$user, input$select_specialty, input$select_index_disease)
    get_cooccurring_diseases(
      atlasview_data$MM_res,
      index_disease = input$select_index_disease,
      specialty = input$select_specialty,
      specialty_filter = caterpillarFilter()
    )
  })
  
  output$outputCaterpillar <- renderPlot(
    {
      req(res_auth$user, input$select_specialty, input$select_index_disease)
      
      MM_res_spe_phe_selected <- MM_res_spe_phe_selected()
      if (nrow(MM_res_spe_phe_selected) > 0) {
        caterpillar_prev_ratio_v5_view(
          MM_res_spe_phe_selected, atlasview_data$n_dis_spe,
          spe_index_dis = input$specialty, atlasview_data$specialty_colours
        )
      }
    },
    height = function() {
      n_rows <- nrow(MM_res_spe_phe_selected())
      max(n_rows * 900/50, 500)  # use 900 pixels per 50 rows and 500 pixels minimum
    }
  )

  # CIRCOS TAB ##############################################################

  output$circosPlot <- svgPanZoom::renderSvgPanZoom({
    req(input$select_index_disease)
    # The statement below clears the area when the tab loses focus. Might be
    # useful if the delay in updating is too disorienting
    # idea from https://stackoverflow.com/questions/63135824/is-there-a-way-to-prevent-shiny-from-remembering-the-old-image-when-switching
    # if (input$panels != "circos") return()

    # We cache circos plots, because they are expensive to generate
    circos_cache_dir <- get_data_filepath("circos-cache")
    if (!dir.exists(circos_cache_dir)) dir.create(circos_cache_dir)
    plot_filename <- paste0(file.path(circos_cache_dir, "plot_"), input$select_index_disease, ".svg")
    
    # if we haven't a saved copy of the plot
    if (!file.exists(plot_filename)) {
      selected_index_disease <- atlasview_data$n_dis_spe$index_dis == input$select_index_disease
      patient_count <- atlasview_data$n_dis_spe$n_indiv_index_dis_m_r[selected_index_disease]
      cooccurring <- get_cooccurring_diseases(atlasview_data$MM_res, input$select_index_disease)
      make_circos_plot(atlasview_data$specialties,
        cooccurring, patient_count,
        svg_filepath = plot_filename
      )
    }
    plot <- readr::read_file(plot_filename)
    svgPanZoom::svgPanZoom(plot, zoomScaleSensitivity = 0.2)
  })

  # COMMENTS TAB #############################################################

  observeEvent(
    list(input$select_specialty, input$select_index_disease),
    {
      req(res_auth$user)
      page_url <- "" # an empty page URL disables comments
      if (input$select_index_disease != "") {
        page_url <- paste0("/?disease=", input$select_specialty, "$", input$select_index_disease)
      }
      shinyjs::js$updateRemark(page_url)
    }
  )
}
