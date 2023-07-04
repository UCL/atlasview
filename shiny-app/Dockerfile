FROM rocker/r-ver:4

# some R packages need to be built from source
RUN apt update && apt install -y git-core libcurl4-openssl-dev libgit2-dev libicu-dev libssl-dev libxml2-dev make pandoc pandoc-citeproc libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev unixodbc-dev fontconfig fonts-liberation && rm -rf /var/lib/apt/lists/*
RUN fc-cache -f -v
  RUN echo "options(repos = c(CRAN = 'http://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" >> /usr/local/lib/R/etc/Rprofile.site

# littler helper script provided by rocker image to install R packages (some binary)
RUN install2.r circlize readr stringr svglite dplyr shiny shinydashboard shinybusy svgPanZoom recogito devtools
RUN install2.r tibble data.table ggplot2 survival rms Hmisc scales RColorBrewer gridExtra hablar gridExtra png grid dplyr tidyr ggiraph Rcpp patchwork
RUN install2.r shinyjs
RUN install2.r jose
RUN install2.r cookies

# atlasview shiny app
RUN mkdir /build_zone
ADD . /build_zone
WORKDIR /build_zone

# we don't want to use renv for the docker container (packages already install above)
# otherwise, we image build takes long time every time shiny app changes
RUN rm .Rprofile

EXPOSE 3838

# TODO: create an atlasview R package, and install properly into environment
CMD R -e "options('shiny.port' = 3838,shiny.host='0.0.0.0'); devtools::load_all(); atlasviewApp()"

# to build: docker build -t atlasview .
# to run:   docker run -p 3838:3838 atlasview


