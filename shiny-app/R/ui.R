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

atlasview_ui <- fluidPage(
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
      inputPanel(
        selectInput(
          inputId = "input_keyq86ilc1",
          label = "Filtering",
          choices = NULL
        )
      ),
      plotOutput(
        outputId = "output_4y6g0lmyjb"
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
    )
  ),
  mainPanel(
    fluidRow(column(12, 
                    HTML('
             <script>
  var remark_config = {
    host: location.protocol + "//" + location.host + "/remark",
    site_id: "atlasview",
    simple_view: false,
    show_email_subscription: false,
    show_rss_subscription: false,
  }
</script>
             <script>!function(e,n){for(var o=0;o<e.length;o++){var r=n.createElement("script"),c=".js",d=n.head||n.body;"noModule"in r?(r.type="module",c=".mjs"):r.async=!0,r.defer=!0,r.src=remark_config.host+"/web/"+e[o]+c,d.appendChild(r)}}(remark_config.components||["embed"],document);</script>
            <script>$.get(location.protocol + "//" + location.host + "/remark/login") </script> 
             <div id="remark42"></div>
             <!-- hide the logout box -->
             <script>
             var iframe = $("iframe", $("#remark42")[0])[0];
             
             $(document).ready(function() { 
    $(iframe).load(function() { 
        $(".user-logout-button", $(iframe).contents()).remove();
    });
});
            
             
             
             
             </script>
             '
                    )
    ))
    
  )
  
)
