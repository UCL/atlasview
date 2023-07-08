atlasviewApp <- function(...) {
  
  specialties <- get_specialties()
  
  speciality_colours <- read.csv(get_data_filepath("lkp_spe_col.csv"), header = TRUE)
  specialties <- specialties %>% dplyr::left_join(y = speciality_colours, by="speciality")   # for circos plots
  speciality_colours <- setNames(as.character(speciality_colours$color), speciality_colours$speciality)  # for caterpillar plots
  
  #read full MM res in vis format
  MM_res <- data.table::fread(file=get_data_filepath("MM_for_circo_network_vis_20230707.csv")) %>% 
    dplyr::left_join(y = specialties, by=c("speciality_index_dis" = "speciality")) %>%
    dplyr::rename("speciality_code" = "code") %>%
    dplyr::left_join(y = specialties, by=c("speciality_cooccurring_dis" = "speciality")) %>%
    dplyr::rename("cooccurring_specialty_code" = "code")
  
  #N of diseases and specialities 
  n_dis_spe <- data.table::fread(file = get_data_filepath("MM_2_n_Feb03_20230707.csv"))
  
  # information about index and coocurring diseases
  index_diseases <- MM_res %>% 
    dplyr::select(phecode_index_dis, phenotype_index_dis, speciality_index_dis, speciality_code) %>% 
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
        if (length(user) & length(user$user) & is.null(cookies::get_cookie("JWT"))) {
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
    
    
    # When speciality has been selected, update the list of index diseases
    observeEvent(input$select_speciality, {
      req(res_auth$user)
      
      # get the index diseases for the speciality
      index_diseases <- index_diseases %>% dplyr::filter(speciality_code == input$select_speciality) %>% dplyr::select(phecode_index_dis, phenotype_index_dis)
      
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
        # no index diseases found for the speciality - empty the select box
        updateSelectizeInput(session=getDefaultReactiveDomain(),
                             input="select_index_disease",
                             choices=list(),
                             selected=NULL,
                             options=list(placeholder=''))
        
      }
    })
    
    # Update the title (used in both page header and window title) when the selection of specialty/disease changes
    pageTitle <- eventReactive(list(input$select_speciality, input$select_index_disease), {
      req(res_auth$user)
      title <- "AtlasView"
      if (input$select_speciality != "") {
        speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
        title <- paste0(title, ": ", speciality_label)
        
        if (!is.null(input$select_index_disease) & input$select_index_disease != "") {
          index_disease_label <- index_diseases[index_diseases$phecode_index_dis == input$select_index_disease, "phenotype_index_dis"]
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
      plot_filename = paste0("plot_", input$select_index_disease, ".svg")
      
      # if we haven't generated the plot already
      if (!file.exists(plot_filename)) {
        patient_count <- n_dis_spe$n_indiv_index_dis_m_r[n_dis_spe$index_dis == input$select_index_disease]
        make_plot(specialties, get_cooccurring_diseases(MM_res, input$select_index_disease), patient_count, to_svg=TRUE)
      }
      
      svgPanZoom::svgPanZoom(readr::read_file(plot_filename), zoomScaleSensitivity=0.2)
    })
    
    # CATERPILLAR TAB ##########################################################

    observeEvent(list(input$qaselect_speciality, input$select_index_disease), {
      req(res_auth$user, input$select_speciality)
      speciality_label <- specialties$speciality[specialties$code == input$select_speciality]
      cooccurring_diseases <- MM_res %>%
        dplyr::filter(speciality_index_dis == speciality_label, phecode_index_dis == input$select_index_disease) %>%
        dplyr::select(speciality_cooccurring_dis) %>% dplyr::distinct() %>% dplyr::arrange(speciality_cooccurring_dis) %>% dplyr::pull()
      
      updateSelectInput(session, 'filter', choices = cooccurring_diseases, selected = cooccurring_diseases)
    })
    
    observeEvent(list(input$select_speciality, input$select_index_disease), {
      req(res_auth$user, input$select_speciality, input$select_index_disease)
      page_url <- ""
      if (input$select_index_disease != "") {
        speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
        index_disease_label <- index_diseases[index_diseases$phecode_index_dis == input$select_index_disease, "phenotype_index_dis"]
        page_url <- paste0(input$select_speciality, input$select_index_disease)
      }
      shinyjs::js$updateRemark(page_url)
    })
    
    output$outputCaterpillar <- renderPlot({
      req(res_auth$user)
      if (input$select_speciality != "" & !is.null(input$select_index_disease) & input$select_index_disease != "") {
        speciality_label <- specialties$speciality[specialties$code == input$select_speciality]
        MM_res_spe <- MM_res  %>% dplyr::filter(speciality_index_dis == speciality_label)
        MM_res_spe_phe <- MM_res_spe %>% dplyr::filter(phecode_index_dis == input$select_index_disease)
        MM_res_spe_phe_selected <- MM_res_spe_phe %>% dplyr::filter(speciality_cooccurring_dis %in% input$filter)
        if (nrow(MM_res_spe_phe_selected) > 0) {
          caterpillar_prev_ratio_v5_view(MM_res_spe_phe_selected,  n_dis_spe,  spe_index_dis=input$specialty, speciality_colours)
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
