

get_atlasview_ui <- function() {
  jsCode <- "
    shinyjs.updateRemark = function(params) {
      if (typeof window.REMARK42.destroy == 'function') {
        window.REMARK42.destroy();
      }
      
      if (params[0] != '') {
        remark_config['url'] = params[0]; 
        reload_js('/remark/web/embed.js'); 
        console.log(remark_config);
      }
    }"
  
  remarkConfig <- "
      function reload_js(src) {
        $('script[src=\"' + src + '\"]').remove();
        $('<script>').attr('src', src).appendTo('head');
      }

      var remark_config = {
        host: location.protocol + '//' + location.host + '/remark',
        site_id: 'atlasview',
        url: 'root',
        simple_view: false,
        show_email_subscription: false,
        show_rss_subscription: false
      }"
  
  cookies::add_cookie_handlers(fluidPage(
  shinyjs::useShinyjs(),
  tags$head(tags$script(HTML(remarkConfig))),
  tags$head(tags$script(src = "/remark/web/embed.js")),
  shinyjs::extendShinyjs(text = jsCode, functions = c("updateRemark")),
  title = "AtlasView",
  shinytitle::use_shiny_title(),
  titlePanel(textOutput("pageTitle")),
  wellPanel(
    selectizeInput('select_specialty', 
                   'Specialty', 
                   choices = list(), 
                   options = list(placeholder = '')), 
   selectizeInput( 'select_index_disease','Index disease', choices = list(), options = list(placeholder = '') ),
  ),
  conditionalPanel("output.nrows", 
  tabsetPanel(
    id="panels",
    type = "tabs",
    tabPanel(
      title = "caterpillar",
      value = "caterpillar",
      wellPanel(
        selectInput('filter', 'Filter', choices = c(), multiple=TRUE),
      ),
      plotOutput(
        outputId = "outputCaterpillar",
        width="100%"
      )
    ),
    tabPanel(
      title = "circos",
      value = "circos",
      shinydashboard::box(width=12,
          shinybusy::add_busy_spinner(spin = "fading-circle"),
          svgPanZoom::svgPanZoomOutput(outputId = "circosPlot", width="100%", height="1000px")
      )
    ),
    tabPanel(
      title = "comments",
      value = "comments",
  mainPanel(
    fluidRow(column(12,  HTML('<div id="remark42"></div>')))
    ) 
    )
  )),
))
}

