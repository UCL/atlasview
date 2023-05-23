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
