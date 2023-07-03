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

jsCode <- "shinyjs.updateRemark = function(params) {
  if (typeof window.REMARK42.destroy == 'function') {
    window.REMARK42.destroy();
  }
  
  if (params[0] != '') {
    remark_config['url'] = params[0]; 
    reload_js('/remark/web/embed.js'); 
    console.log(remark_config);
  }
}"

atlasview_ui <- fluidPage(
  shinyjs::useShinyjs(),
  tags$head(tags$script(HTML("
      function reload_js(src) {
        $('script[src=\"' + src + '\"]').remove();
        $('<script>').attr('src', src).appendTo('head');
      }
    
  var remark_config = {
          host: location.protocol + '//' + location.host + '/remark',
          site_id: 'atlasview',
          url: 'testing',
          simple_view: false,
          show_email_subscription: false,
          show_rss_subscription: false,
  }
  
                             "
  ))),
  tags$head(tags$script(src = "/remark/web/embed.js")),
  extendShinyjs(text = jsCode, functions = c("updateRemark")),
  title = "Shiny Application",
  h1(
    uiOutput('pageHeader')
  ),
  wellPanel(
    selectizeInput('select_speciality', 
                   'Speciality', 
                   choices = split(specialties$code, specialties$speciality), 
                   options = list(placeholder = 'Please select a speciality', 
                                  onInitialize = I('function() { this.setValue(""); }'))
    ), 
   selectizeInput( 'select_index_disease','Index disease', choices = list(), options = list(placeholder = '') ),
  ),
  tabsetPanel(
    type = "tabs",
    tabPanel(
      title = "caterpillar",
      value = "caterpillar",
      wellPanel(
        selectInput('filter', 'Filter', choices = c(), multiple=TRUE),
      ),
      plotOutput(
        outputId = "outputCaterpillar"
      )
    ),
    tabPanel(
      title = "circos",
      value = "circos",
      box(width=12,
          title=textOutput(outputId="indexDiseaseName"),
          add_busy_spinner(spin = "fading-circle"),
          svgPanZoomOutput(outputId = "circosPlot", width="1000px", height="1000px")
      )
    ),
    tabPanel(
      title = "discussion",
      value = "discussion",
  mainPanel(
    fluidRow(column(12,  HTML('<div id="remark42"></div>')))
    ) 
    )
  ),
)
