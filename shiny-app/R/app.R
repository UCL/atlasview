atlasviewApp <- function(...) {
  server <-  function(input, output) {
  }
  
  shinyApp(ui = atlasview_ui, server = server)
}

