#' Launch the atlasview Shiny app
#' @export
atlasviewApp <- function() {
  shinyApp(
    ui = shinymanager::secure_app(
      head_auth = tags$script('$.get(location.protocol + "//" + location.host + "/remark/auth/logout")'), # logout any existing user from Remark engine on login page
      atlasview_ui()
    ),
    server = atlasview_server
  )
}
