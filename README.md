1. Clone this repository
2. Start R in the top-level of the repository
    - renv will be installed
3. Installed the required dependencies with `renv::restore()`
4. Install devtools with `install.packages("devtools")`
5. Put the file `MM_for_circo_network_vis_29112022.csv` in `inst/extdata`
6. Load the package with `devtools::load_all()`
7. Run the Shiny app using `myApp()`


Notes: 

- Update latest version of devtools: https://www.r-project.org/nosvn/pandoc/devtools.html

Docker (example?): https://github.com/DavidASmith/r-shiny-docker-renv/blob/main/Dockerfile

https://grahamgilbert.com/blog/2017/04/04/using-caddy-to-https-all-the-things/
https://nip.io/
https://caddyserver.com/docs/automatic-https

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/dynamic-dns.html


https://caddyserver.com/docs/automatic-https

https://cran.r-project.org/web/packages/jose/vignettes/jwt.html

# setting new URL and refreshing remark
remark_config["url"] = "testing"; window.REMARK42.destroy(); reload_js("/remark/web/embed.js")


digest::digest(jwt, algo="sha1")
stringr::str_c("atlasview_", digest::sha1("asif_tamuri"))

get("ATLASVIEW_USER", envir=session$request)

ubuntu@ip-192-168-56-233:~/atlasview$ git submodule init
ubuntu@ip-192-168-56-233:~/atlasview$ git submodule update


credentials go in atlasview-data/users.csv
passwords are hashed in R using: `scrypt::hashPassword("my_password")`

to run something when user logs out:
    observeEvent(session$input$.shinymanager_logout, {
      print('you logged out')
    })
    

