atlasviewApp <- function(...) {
  
  #read full MM res in vis format
  path_file_MM_res <-  get_data_filepath("MM_for_circo_network_vis_25052023.csv")
  MM_res <- data.table::fread(file=path_file_MM_res)
  MM_res <- MM_res %>% dplyr::filter(speciality_index_dis != 'GMC')

  #N of diseases and specialities 
  path_file_M2 <- get_data_filepath("MM_2_n_Feb03_25052023.csv")
  
  n_dis_spe <- data.table::fread(file = path_file_M2)
  
  # information about index and coocurring diseases
  fpath3 <- get_data_filepath("MM_for_circo_network_vis_29112022.csv")
  
  index_diseases <- readr::read_csv(fpath3, show_col_types = FALSE) %>% 
    dplyr::select(phecode_index_dis, phenotype_index_dis) %>% 
    dplyr::distinct() %>% 
    dplyr::arrange(phenotype_index_dis) %>%
    dplyr::mutate(speciality_code="GAST")  # TODO: this data only has GAST diseases

  
  # ---- DATA ----
  # (From Ana)
  fpath1 <- get_data_filepath("MM_for_circo_network_vis_29112022.csv")
  fpath2 <- get_data_filepath("lkp_unique_spec_circo_plot.csv")
  fpath3 <- get_data_filepath("lkp_unique_spec_circo_plot_codes.csv")
  
  MM_for_circo_network_vis_29112022 <- readr::read_csv(fpath1,show_col_types = FALSE  )
  lkp_unique_spec_circo_plot <- readr::read_csv(fpath2,show_col_types = FALSE )
  lkp_unique_spec_circo_plot_codes <- readr::read_csv(fpath3, show_col_types = FALSE)
  
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
    # call the server part
    # check_credentials returns a function to authenticate users
    res_auth <- shinymanager::secure_server(
      check_credentials = shinymanager::check_credentials(get_credentials())
    )
    
    not_logged_in <- function() {
      return(!length(reactiveValuesToList(res_auth)))
    }
    
    specialties <- get_specialties()
    
    observe({
      user <- reactiveValuesToList(res_auth)
      if (length(user) & length(user$user)) {
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
    })
    
    # update that index disease selection drop-down
    observe({
      if (not_logged_in()) { return() }
      
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
    
    output$indexDiseaseName <- renderText({
      
      if (!is.null(input$select_index_disease) & input$select_index_disease != "") {
        return((index_diseases %>% dplyr::filter(phecode_index_dis == input$select_index_disease) %>% dplyr::select(phenotype_index_dis))[[1,1]])
      } else {
        return('')
      }
    })
    
    # show circos plot for the chosen disease
    output$circosPlot <- svgPanZoom::renderSvgPanZoom({
      # if an index disease has been selected
      if (!is.null(input$select_index_disease) & input$select_index_disease != "") {
        plot_filename = paste0("plot_", input$select_index_disease, ".svg")
        
        # if we haven't generated the plot already
        if (!file.exists(plot_filename)) {
          make_plot(get_cooccurring_diseases(MM_processed, input$select_index_disease), to_svg=TRUE)
        }
        
        svgPanZoom::svgPanZoom(readr::read_file(plot_filename), zoomScaleSensitivity=0.5)
        
      }
    })
    
    # CATERPILLAR TAB ##########################################################

    observe({
      if (not_logged_in()) { return() }
      if (input$select_speciality != "" & !is.null(input$select_index_disease) & input$select_index_disease != "") {
      speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
      cooccurring_diseases <- MM_res %>%
        dplyr::filter(speciality_index_dis == speciality_label, phecode_index_dis == input$select_index_disease) %>%
        dplyr::select(speciality_cooccurring_dis) %>% dplyr::distinct() %>% dplyr::arrange(speciality_cooccurring_dis) %>% dplyr::pull()
      
      updateSelectInput(session, 'filter', choices = cooccurring_diseases, selected = cooccurring_diseases)
      }
    })
    
    toListen <- reactive({
      list(input$select_speciality,input$select_index_disease)
    })
    
    observeEvent(toListen(), {
      if (not_logged_in()) { return() }
      if (input$select_speciality != "" & !is.null(input$select_index_disease) & input$select_index_disease != "") {
        speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
        index_disease_label <- index_diseases[index_diseases$phecode_index_dis == input$select_index_disease, "phenotype_index_dis"]
          page_url <- paste0(input$select_speciality, input$select_index_disease)
      } else  {
        page_url <- ""
      }
      shinyjs::js$updateRemark(page_url)
    })
    
    output$outputCaterpillar <- renderPlot({
      if (not_logged_in()) { return() } 
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
