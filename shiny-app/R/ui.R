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
    document.title = params[0];
    reload_js('/remark/web/embed.js'); 
    console.log(remark_config);
  }
}"

now_utc <- function() {
  now <- Sys.time()
  attr(now, "tzone") <- "UTC"
  now
}

id <- stringr::str_remove_all(uuid::UUIDgenerate(), "-")

authentication <- jose::jwt_claim(
  aud="atlasview",
  exp=as.numeric(now_utc() + lubridate::minutes(10)),
  jti=id,
  iat=as.numeric(now_utc() - lubridate::minutes(10)),
  iss="remark42",
  user=list(
    name="asif_tamuri",
    id="atlasview_348058893e04c7e439153a2a281bb701e7208880",
    picture="https://ui-avatars.com/api/?name=A+T",
    attrs=list(
      admin=FALSE,
      blocked=FALSE
    )
  )
)

authentication <- jose::jwt_encode_hmac(authentication, secret=charToRaw("12345"))

atlasview_ui <- cookies::add_cookie_handlers(fluidPage(
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
  }"
  ))),
  cookies::set_cookie_on_load("JWT", authentication), 
  cookies::set_cookie_on_load("XSRF-TOKEN", id),
  tags$head(tags$script(src = "/remark/web/embed.js")),
  htmlOutput("testingcookie"),
  # tags$head(tags$script(HTML('$.get(location.protocol + "//" + location.host + "/remark/login")'))),
  extendShinyjs(text = jsCode, functions = c("updateRemark")),
  title = "AtlasView",
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
))
