library(dplyr)
library(readr)

library(shiny)
library(shinydashboard)
library(shinybusy)

library(svgPanZoom)

library(recogito)

# where to cache plots
shinyOptions(cache = cachem::cache_disk("./circos-cache"))

# list of all specialties
fpath1 <- system.file("extdata", "lkp_unique_spec_circo_plot.csv", package="atlasview")
fpath2 <- system.file("extdata", "lkp_unique_spec_circo_plot_codes.csv", package="atlasview")

specialties <- cbind(read_csv(fpath1), read_csv(fpath2))

# information about index and coocurring diseases
fpath3 <-  system.file("extdata", "MM_for_circo_network_vis_29112022.csv", package="atlasview")

index_diseases <- read_csv(fpath3) %>% 
  select(phecode_index_dis, phenotype_index_dis) %>% 
  distinct() %>% 
  arrange(phenotype_index_dis) %>%
  mutate(speciality_code="GAST")  # TODO: this data only has GAST diseases

txt <- "Josh went to the bakery in Brussels.\nWhat an adventure!"

myApp <- function(...) {


ui <- fluidPage(
  # add style so selectize control is drawn on top of other elements
  # see here: https://github.com/juba/shinyglide/issues/15
  tags$head(
    tags$style(
      HTML(".selectize-control { position: static !important;; }")
    )
  ),
  
  fluidRow(
    column(width=12, titlePanel("ATLAS"))
  ),
  
  fluidRow(
    box(width = 6, title = "Select speciality and disease", 
      splitLayout(
        selectizeInput('select_speciality', 
                       'Speciality', 
                       choices = split(specialties$code, specialties$speciality), 
                       options = list(placeholder = 'Please select a speciality', 
                                      onInitialize = I('function() { this.setValue(""); }'))
        ), 
        selectizeInput( 'select_index_disease','Disease', choices = list(), options = list(placeholder = '') ),
      )
    )
  ),
  
  fluidRow(
    box(width=12,
        title=textOutput(outputId="indexDiseaseName"),
        add_busy_spinner(spin = "fading-circle"),
        svgPanZoomOutput(outputId = "circosPlot", width="1000px", height="1000px")
    )
  )
)


server <- function(input, output) {
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


shinyApp(ui = ui, server = server)
}
