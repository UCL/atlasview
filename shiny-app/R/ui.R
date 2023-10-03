atlasview_ui <- function() {
  shinyjsCode <- "
    shinyjs.updateRemark = function(params) {
      if (typeof window.REMARK42.destroy == 'function') {
        window.REMARK42.destroy();
      }
      
      if (params[0] != '') {
        remark_config['url'] = params[0]; 
        reload_js('/remark/web/embed.js'); 
        console.log(remark_config);
      }
    }
  "
  
  remarkJsCode <- "
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
      }
  
      function toggle_guide() {
        $('#av-guide').toggle();
        if ($('#av-guide').is(':visible')) {
          $('#av-toggle-guide').text('Hide guide');
        } else {
          $('#av-toggle-guide').text('Show guide');
        }
      }
  "
  
  ui <- fluidPage(
    shinyjs::useShinyjs(),
    tags$head(tags$script(HTML(remarkJsCode))),
    tags$head(tags$script(src = "/remark/web/embed.js")),
    shinyjs::extendShinyjs(text = shinyjsCode, functions = c("updateRemark")),
    
    title = "AtlasViews",
    shinytitle::use_shiny_title(),
    titlePanel(textOutput("pageTitle")),
    div(
      p("The purpose of this website (alpha version) is to get the views of 
        clinicians on the co-occurring disease results in the Disease Atlas.")
      ),
    a(id="av-toggle-guide", href="javascript:toggle_guide();", "Hide guide"),
    br(),
    div(id = "av-guide", 
        br(),
        HTML(
        "<p>
        <strong>Where does the data come from?</strong> The Disease Atlas 
        results on co-occurring diseases are presented for the first time here. 
        In brief in the population of England (56 million people) we defined 
        index diseases and co-occurring diseases using ICD-10 coded 
        hospitalisation data. In England up to 20 diagnosis codes are applied 
        for each admission and the coding standards explicitly mandates coding 
        of all diseases, and is not confined to those directly causing 
        admission. 
        </p>
        <p>
        <strong>What analysis has been performed?</strong> For people with each 
        index disease we estimated the prevalence of up to 100 diseases 
        co-occurring in at least 10 people (‘long tail, pairwise 
        multimorbidity’). We included co-occurring diseases recorded at any time 
        from start of recording (1998) up to the census date (22 Jan 2020). 
        We report two different measures of co-occurrence
        <ul>
          <li />The (absolute) prevalence of a co-occurring disease, 
          irrespective of whether it is more common than expected.
          <li />The excess prevalence of a co-occurring disease, compared to age 
          and sex adjusted prevalence in the whole 56 million population. 
          This is the standardised co-occurrence ratio, SCR.
        </ul>
        </p>
        <p> 
        <strong>How have the results been visualised?</strong> We display the 
        exact same results (prevalence and SCR) in two different ways:
        <ul>
        <li />Circos plot – where each specialty maintains a constant position 
        on the ‘clockface’
        <li />Caterpillar plot - in which the estimates are ranked on SCR
        </ul>
        </p>
        <p>
        Here are some prompts for the kinds of things we are interested in 
        initial feedback on:
        <ol>
        <li />Please provide any <strong>general comments</strong> e.g. the 
        purpose, the data,  analysis or visualisation of results:
        <ul>
        <li />For example is there anything that needs clarification?
        <li />Do you think it is easier for a clinician to understand the Circos 
        plot or the caterpillar plot?
        </ul>
        <li />Please provide <strong>index disease specific comments</strong>.
        For each disease please comment on:
        <ul>
        <li />Are the associations <strong>valid</strong>? – e.g. they reflect 
        what is expected in clinical practice / or are consistent with current 
        research understanding
        <li />Are any of the associations <strong>novel</strong> and not part of
        current clinical thinking?
        <li />Are there any novel associations that you consider to be 
        <strong>clinically relevant</strong>? i.e. might inform patient 
        management.
        </ul>
        </ol>
        </p>
        ")
    ),
    br(),
    display_version(),
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
      )  # end tabsetPanel
    )  # end conditionalPanel
  )  # end fluidPage
  
  ui <- cookies::add_cookie_handlers(ui)
  ui
}

## Display the current version and commit of the app
display_version <- function() {
  ## Get version from the latest git tag
  tags <- gert::git_tag_list()
  version <- tags$name[1]
  commit <- gert::git_info()$commit
  sha <- substr(commit, 1, 7)
  
  ## Create link to commit sha on GitHub
  gh_link <- glue::glue("https://github.com/UCL/atlasview/commit/{sha}")
  html_link <- a(href = gh_link, sha)
  
  ## Format info message with html tags
  info_msg <- div(p(glue::glue("Running atlasview {version} - commit"), html_link))
  
  shiny.info::display(message = info_msg, position = "top right", type = "message")
}
