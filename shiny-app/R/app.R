atlasviewApp <- function(...) {
  
  #read full MM res in vis format
  MM_res <- data.table::fread(file=get_data_filepath("MM_for_circo_network_vis_25052023.csv"))
  MM_res <- MM_res %>% dplyr::filter(speciality_index_dis != 'GMC')

  #N of diseases and specialities 
  n_dis_spe <- data.table::fread(file = get_data_filepath("MM_2_n_Feb03_25052023.csv"))
  
  # information about index and coocurring diseases
  index_diseases <- readr::read_csv(get_data_filepath("MM_for_circo_network_vis_29112022.csv"), show_col_types = FALSE) %>% 
    dplyr::select(phecode_index_dis, phenotype_index_dis) %>% 
    dplyr::distinct() %>% 
    dplyr::arrange(phenotype_index_dis) %>%
    dplyr::mutate(speciality_code="GAST")  # TODO: this data only has GAST diseases
  
  # ---- DATA ----
  MM_for_circo_network_vis_29112022 <- readr::read_csv(get_data_filepath("MM_for_circo_network_vis_29112022.csv"),show_col_types = FALSE  )
  lkp_unique_spec_circo_plot <- readr::read_csv(get_data_filepath("lkp_unique_spec_circo_plot.csv"), show_col_types = FALSE )
  lkp_unique_spec_circo_plot_codes <- readr::read_csv(get_data_filepath("lkp_unique_spec_circo_plot_codes.csv"), show_col_types = FALSE)
  
  # lookup for speciality codes
  spec_codes_merged <- cbind(lkp_unique_spec_circo_plot, lkp_unique_spec_circo_plot_codes)
  spec_codes_merged <- spec_codes_merged[order(spec_codes_merged$code), ]
  
  # ---- add placeholder N ----
  # dummy df with placeholder of N cases in index disease (nphecode)
  df_dummy_N <- data.frame(index_dis = unique(MM_for_circo_network_vis_29112022$phecode_index_dis),
                           nphecode = ' ')
  
  df_dummy_N$nphecode <- sample(100:1000, length(df_dummy_N$nphecode))
  
  
  # ---- PLOT ----
  # add four-letter abbreviations for specialities
  MM_processed <- merge(MM_for_circo_network_vis_29112022, spec_codes_merged, by.x='speciality_cooccurring_dis', by.y='speciality')
  
  # merge placeholder N in index disease
  MM_processed <- merge(MM_processed, df_dummy_N, 
                        by.x='phecode_index_dis', 
                        by.y='index_dis')
  
  
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
    
    specialties <- get_specialties()
    
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
      plot_filename = paste0("plot_", input$select_index_disease, ".svg")
      
      # if we haven't generated the plot already
      if (!file.exists(plot_filename)) {
        make_plot(MM_processed, spec_codes_merged, get_cooccurring_diseases(MM_processed, input$select_index_disease), to_svg=TRUE)
      }
      
      svgPanZoom::svgPanZoom(readr::read_file(plot_filename), zoomScaleSensitivity=0.2)
    })
    
    # CATERPILLAR TAB ##########################################################

    observeEvent(list(input$select_speciality, input$select_index_disease), {
      req(res_auth$user, input$select_speciality, input$select_index_disease)
      speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
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
        speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
        MM_res_spe <- MM_res  %>% dplyr::filter(speciality_index_dis == speciality_label)
        MM_res_spe_phe <- MM_res_spe %>% dplyr::filter(phecode_index_dis == input$select_index_disease)
        MM_res_spe_phe_selected <- MM_res_spe_phe %>% dplyr::filter(speciality_cooccurring_dis %in% input$filter)
        if (nrow(MM_res_spe_phe_selected) > 0) {
          caterpillar_prev_ratio_v5_view(MM_res_spe_phe_selected,  n_dis_spe,  spe_index_dis=input$specialty)
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
