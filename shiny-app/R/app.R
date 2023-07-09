atlasviewApp <- function(...) {
  
  specialties <- get_specialties()
  
  specialty_colours <- read.csv(get_data_filepath("lkp_spe_col.csv"), header = TRUE)
  specialties <- specialties %>% dplyr::left_join(y = specialty_colours, by="specialty")   # for circos plots
  specialty_colours <- setNames(as.character(specialty_colours$color), specialty_colours$specialty)  # for caterpillar plots
  
  #read full MM res in vis format
  MM_res <- data.table::fread(file=get_data_filepath("MM_for_circo_network_vis_20230707.csv")) %>% 
    dplyr::left_join(y = specialties, by=c("specialty_index_dis" = "specialty")) %>%
    dplyr::rename("specialty_code" = "code") %>%
    dplyr::left_join(y = specialties, by=c("specialty_cooccurring_dis" = "specialty")) %>%
    dplyr::rename("cooccurring_specialty_code" = "code")
  
  #N of diseases and specialities 
  n_dis_spe <- data.table::fread(file = get_data_filepath("MM_2_n_Feb03_20230707.csv"))
  
  # information about index and coocurring diseases
  index_diseases <- MM_res %>% 
    dplyr::select(phecode_index_dis, phenotype_index_dis, specialty_index_dis, specialty_code) %>% 
    dplyr::distinct() %>% 
    dplyr::arrange(phenotype_index_dis)
  
  server <-  function(input, output, session) {
    # User must be authenticated to access the app. Check for res_auth$user
    res_auth <- shinymanager::secure_server(
      check_credentials = shinymanager::check_credentials(get_credentials())
    )
    
    # When user has been authenticated, create the JWT and XSRF tokens required
    # to automatically login to Remark comment engine
    observeEvent(
      res_auth$user,
      {
        req(res_auth$user)
        user <- reactiveValuesToList(res_auth)
        if (is.null(cookies::get_cookie("JWT"))) {
          # TODO: we need to remove these cookies on visit to the login screen 
          # (when running shiny app in rstudio - already works when deployed to prod)
          jwt <- make_jwt(user$user)
          xsrf <- jwt$jti
          jwt <- jose::jwt_encode_hmac(jwt, secret=charToRaw(Sys.getenv("REMARK_SECRET")))
          cookies::set_cookie("JWT", jwt)
          cookies::set_cookie("XSRF-TOKEN", xsrf)
        }
      }
    )
    
    observeEvent(res_auth$user, {
      req(res_auth$user)
      
      users_specialties <- get_specialties() %>% dplyr::filter(stringr::str_detect(code, res_auth$specialty_codes))
      
      updateSelectizeInput(session = getDefaultReactiveDomain(),
                           inputId = "select_specialty",
                           choices = split(users_specialties$code, users_specialties$specialty), 
                           selected = NULL,
                           options = list(placeholder = 'Please select a specialty', 
                                          onInitialize = I('function() { this.setValue(""); }'))
      )
    })
    
    
    # When specialty has been selected, update the list of index diseases
    observeEvent(input$select_specialty, {
      req(res_auth$user)
      
      # get the index diseases for the specialty
      index_diseases <- index_diseases %>% dplyr::filter(specialty_code == input$select_specialty) %>% dplyr::select(phecode_index_dis, phenotype_index_dis)
      
      # if any were found
      if (nrow(index_diseases) > 0) {
        # update the index disease select box
        updateSelectizeInput(session=getDefaultReactiveDomain(),
                             inputId = "select_index_disease", 
                             choices = split(index_diseases$phecode_index_dis, index_diseases$phenotype_index_dis), 
                             selected = NULL, 
                             options = list(placeholder = 'Please select an index disease', 
                                            onInitialize = I('function() { this.setValue(""); }'))
        )
      } else {
        # no index diseases found for the specialty - empty the select box
        updateSelectizeInput(session=getDefaultReactiveDomain(),
                             input="select_index_disease",
                             choices=list(),
                             selected=NULL,
                             options=list(placeholder=''))
        
      }
    })
    
    # Update the title (used in both page header and window title) when the selection of specialty/disease changes
    pageTitle <- eventReactive(list(input$select_specialty, input$select_index_disease), {
      req(res_auth$user)
      title <- "AtlasView"
      if (input$select_specialty != "") {
        specialty_label <- specialties[specialties$code == input$select_specialty, "specialty"]
        title <- paste0(title, ": ", specialty_label)
        
        if (!is.null(input$select_index_disease) & input$select_index_disease != "") {
          index_disease_label <- index_diseases$phenotype_index_dis[index_diseases$phecode_index_dis == input$select_index_disease]
          title <- paste0(title, " → ", index_disease_label)
        }
      }
      title
    })
    
    output$pageTitle <- renderText({
      pageTitle()
    })
    
    observeEvent(pageTitle(), {
      shinytitle::change_window_title(session, pageTitle())
    })
    
    # Generate and display the circos diagram
    output$circosPlot <- svgPanZoom::renderSvgPanZoom({
      req(input$select_index_disease)
      # the statement below clears the area when the tab loses focus. might be
      # useful if the delay in updating is too disorienting
      # idea from https://stackoverflow.com/questions/63135824/is-there-a-way-to-prevent-shiny-from-remembering-the-old-image-when-switching
      # if (input$panels != "circos") return()
      plot_filename = get_data_filepath(paste0("circos-cache/plot_", input$select_index_disease, ".svg"))
      
      # if we haven't generated the plot already
      if (!file.exists(plot_filename)) {
        patient_count <- n_dis_spe$n_indiv_index_dis_m_r[n_dis_spe$index_dis == input$select_index_disease]
        make_plot(specialties, get_cooccurring_diseases(MM_res, input$select_index_disease), patient_count, svg_filepath=plot_filename)
      }
      
      svgPanZoom::svgPanZoom(readr::read_file(plot_filename), zoomScaleSensitivity=0.2)
    })
    
    # CATERPILLAR TAB ##########################################################

    observeEvent(list(input$qaselect_specialty, input$select_index_disease), {
      req(res_auth$user, input$select_specialty)
      specialty_label <- specialties$specialty[specialties$code == input$select_specialty]
      cooccurring_diseases <- MM_res %>%
        dplyr::filter(specialty_index_dis == specialty_label, phecode_index_dis == input$select_index_disease) %>%
        dplyr::select(specialty_cooccurring_dis) %>% dplyr::distinct() %>% dplyr::arrange(specialty_cooccurring_dis) %>% dplyr::pull()
      
      updateSelectInput(session, 'filter', choices = cooccurring_diseases, selected = cooccurring_diseases)
    })
    
    observeEvent(list(input$select_specialty, input$select_index_disease), {
      req(res_auth$user, input$select_specialty, input$select_index_disease)
      page_url <- ""
      if (input$select_index_disease != "") {
        specialty_label <- specialties[specialties$code == input$select_specialty, "specialty"]
        index_disease_label <- index_diseases[index_diseases$phecode_index_dis == input$select_index_disease, "phenotype_index_dis"]
        page_url <- paste0(input$select_specialty, input$select_index_disease)
      }
      shinyjs::js$updateRemark(page_url)
    })
    
    caterpillarFilter <- reactive({
      input$filter
    })
    
    debouncedCaterpillarFilter <- caterpillarFilter %>% debounce(1000)
    
    output$outputCaterpillar <- renderPlot({
      req(res_auth$user)
      if (input$select_specialty != "" & !is.null(input$select_index_disease) & input$select_index_disease != "") {
        specialty_label <- specialties$specialty[specialties$code == input$select_specialty]
        MM_res_spe <- MM_res  %>% dplyr::filter(specialty_index_dis == specialty_label)
        MM_res_spe_phe <- MM_res_spe %>% dplyr::filter(phecode_index_dis == input$select_index_disease)
        MM_res_spe_phe_selected <- MM_res_spe_phe %>% dplyr::filter(specialty_cooccurring_dis %in% debouncedCaterpillarFilter())
        if (nrow(MM_res_spe_phe_selected) > 0) {
          caterpillar_prev_ratio_v5_view(MM_res_spe_phe_selected,  n_dis_spe,  spe_index_dis=input$specialty, specialty_colours)
        }
      }
    },
    width=1000, height=900)
  }
  
  shinyApp(
    ui = shinymanager::secure_app(
      head_auth=tags$script('$.get(location.protocol + "//" + location.host + "/remark/auth/logout")'), 
      get_atlasview_ui()
    ), 
    server = server)
}
