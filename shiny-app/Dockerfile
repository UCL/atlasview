FROM rocker/shiny-verse:4

ENV DEBIAN_FRONTEND noninteractive

# https://askubuntu.com/a/25614
RUN apt update
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
RUN apt install -y --no-install-recommends fontconfig ttf-mscorefonts-installer
RUN fc-cache -f -v

# should already be installed in base image
RUN install2.r --error --skipinstalled --ncpus 1 \
    data.table devtools dplyr ggplot2 grid RColorBrewer Rcpp readr scales shiny stringr survival tibble tidyr

# additional packages needed for atlasview app
RUN install2.r --error --skipinstalled --ncpus 1 \ 
    circlize cookies ggiraph gridExtra hablar Hmisc jose patchwork png recogito rms shinybusy shinydashboard shinyjs shinymanager shinytitle svgPanZoom svglite


# install the atlasview shiny app
RUN mkdir /build_zone
ADD . /build_zone
WORKDIR /build_zone

# we don't want to use renv for the docker container (packages already install above)
# otherwise, the image build takes long time every time shiny app changes
RUN rm .Rprofile

EXPOSE 3838

# TODO: create an atlasview R package, and install properly into environment
CMD R -e "options('shiny.port' = 3838,shiny.host='0.0.0.0'); devtools::load_all(); atlasviewApp()"

# to build: docker build -t atlasview .
# to run:   docker run -p 3838:3838 atlasview


