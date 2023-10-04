## Set the version of the Shiny app to the latest git tag
## ======================================================

usethis::proj_activate("shiny-app")

tags <- gert::git_tag_list()
version <- sub("^v", "", tags$name[1])

## Update DESCRIPTION file
desc <- desc::desc()
desc$set_version(version)
desc$write()

usethis::ui_done("Bumped version of atlasview to {version}")
