atlasview_ui <- fluidPage(
  title = "Shiny Application",
  h1(
    "AtlasView"
  ),
  inputPanel(
    selectInput(
      inputId = "input_ahit0meg1y",
      label = "Speciality",
      choices = NULL
    ),
    selectInput(
      inputId = "input_unhzahtfhg",
      label = "Index disease",
      choices = NULL
    )
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
      plotOutput(
        outputId = "output_bxnu7x9xpc"
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
