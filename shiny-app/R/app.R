library(dplyr)
library(readr)

library(shiny)
library(shinydashboard)
library(shinybusy)

library(svgPanZoom)

library(recogito)

library(tibble)
library(data.table)
library(ggplot2)
library(survival)
library(rms)
library(Hmisc)
library(scales)
library(RColorBrewer)
library(gridExtra)
library(hablar)
library(gridExtra)
library(png)
library(grid)
library(dplyr)
library(tidyr)
library(ggiraph)
library(Rcpp)
library(patchwork)

library(shinyjs)

home_res <- '/Users/tamuri/University College London/Torralbo, Ana - atlasview'

data_path <- Sys.getenv("ATLASVIEW_DATA_PATH")
if (data_path != "") {
  home_res <- data_path
}

###############################################################################

#speciality colors from lkp
fpath1 <- system.file("extdata", "lkp_spe_col.csv", package="atlasview")
my_colors <- read.csv(file = fpath1, header = TRUE)
my_colors <- my_colors%>% filter(speciality != 'GMC')

my_colors$speciality
my_cols <- my_colors$color
names(my_cols) <- my_colors$speciality
colScale <- scale_color_manual(values=my_cols)

###############################################################################

#read full MM res in vis format
path_file_MM_res <- paste(home_res, "/MM_for_circo_network_vis_25052023.csv", sep = '')

MM_res <- fread(file=path_file_MM_res)
MM_res <- MM_res %>% filter(speciality_index_dis != 'GMC')

###############################################################################

#N of diseases and specialities 
path_file_M2 <- paste(home_res, "/MM_2_n_Feb03_25052023.csv", sep = '')

n_dis_spe <- fread(file = path_file_M2)

###############################################################################



atlasviewApp <- function(...) {
  server <-  function(input, output, session) {
    
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
    
    output$pageHeader <- renderUI({
      title <- "AtlasView"
      if (input$select_speciality != "") {
        speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
        title <- paste0(title, " > ", speciality_label)
        
        if (!is.null(input$select_index_disease) & input$select_index_disease != "") {
          index_disease_label <- index_diseases[index_diseases$phecode_index_dis == input$select_index_disease, "phenotype_index_dis"]
          title <- paste0(title, " > ", index_disease_label)
        }
      }
      
      h1(title)
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
    
    # CATERPILLAR TAB ##########################################################

    observe({
      if (input$select_speciality != "" & !is.null(input$select_index_disease) & input$select_index_disease != "") {
      print("here 1")
      speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
      cooccurring_diseases <- MM_res %>%
        filter(speciality_index_dis == speciality_label, phecode_index_dis == input$select_index_disease) %>%
        select(speciality_cooccurring_dis) %>% distinct() %>% arrange(speciality_cooccurring_dis) %>% pull()
      
      updateSelectInput(session, 'filter', choices = cooccurring_diseases, selected = cooccurring_diseases)
      }
    })
    
    toListen <- reactive({
      list(input$select_speciality,input$select_index_disease)
    })
    
    observeEvent(toListen(), {
      if (input$select_speciality != "" & !is.null(input$select_index_disease) & input$select_index_disease != "") {
          page_url <- paste0(input$select_speciality, input$select_index_disease)
      } else  {
        page_url <- ""
      }
      shinyjs::js$updateRemark(page_url)
    })
    
    output$outputCaterpillar <- renderPlot({
      if (input$select_speciality != "" & !is.null(input$select_index_disease) & input$select_index_disease != "") {
        print("here 2")
        speciality_label <- specialties[specialties$code == input$select_speciality, "speciality"]
        MM_res_spe <- MM_res  %>% filter(speciality_index_dis == speciality_label)
        MM_res_spe_phe <- MM_res_spe %>% filter(phecode_index_dis == input$select_index_disease)
        MM_res_spe_phe_selected <- MM_res_spe_phe %>% filter(speciality_cooccurring_dis %in% input$filter)
        if (nrow(MM_res_spe_phe_selected) > 0) {
          caterpillar_prev_ratio_v5_view(MM_res_spe_phe_selected,  n_dis_spe,  spe_index_dis=input$specialty)
        }
      }
    },
    width=1000,
    height=1000)
    
  }
  
  shinyApp(ui = atlasview_ui, server = server)
}

