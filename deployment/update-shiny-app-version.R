## Set the version of the Shiny app to the latest git tag
## ======================================================

atlasview_root <- file.path(Sys.getenv("HOME"), "atlasview")
usethis::proj_activate(file.path(atlasview_root, "shiny-app"))

tags <- gert::git_tag_list()
version <- sub("^v", "", tags$name[length(tags$name)])

usethis::ui_info("Setting version to {version}")

## Update DESCRIPTION file
desc <- desc::desc()
desc$set_version(version)
desc$write()

usethis::ui_done("Bumped version of atlasview to {version}")
