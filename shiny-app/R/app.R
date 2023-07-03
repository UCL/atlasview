atlasviewApp <- function(...) {
  server <-  function(input, output) {
    
    # update that index disease selection drop-down
    observe({
      # get the index diseases for the speciality
      index_diseases <- index_diseases %>% filter(speciality_code == input$select_speciality) %>% select(phecode_index_dis, phenotype_index_dis)
      
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
    
    output$indexDiseaseName <- renderText({
      if (!is.null(input$select_index_disease) & input$select_index_disease != "") {
        return((index_diseases %>% filter(phecode_index_dis == input$select_index_disease) %>% select(phenotype_index_dis))[[1,1]])
      } else {
        return('')
      }
    })
    
    # show circos plot for the chosen disease
    output$circosPlot <- renderSvgPanZoom({
      # if an index disease has been selected
      if (!is.null(input$select_index_disease) & input$select_index_disease != "") {
        plot_filename = paste0("plot_", input$select_index_disease, ".svg")
        
        # if we haven't generated the plot already
        if (!file.exists(plot_filename)) {
          make_plot(get_cooccurring_diseases(MM_processed, input$select_index_disease), to_svg=TRUE)
        }
        
        svgPanZoom(read_file(plot_filename), zoomScaleSensitivity=0.5)
        
      }
    })
    
  }
  
  shinyApp(ui = atlasview_ui, server = server)
}

