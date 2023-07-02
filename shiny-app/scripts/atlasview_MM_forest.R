
rm(list=ls())

#library(qdap)
library(data.table)
library(ggplot2)
library(survival)
library(rms)
library(Hmisc)
library(scales)
library(RColorBrewer)
library(gridExtra)
library(hablar)
library(gridExtra)
library(png)
library(grid)
library(dplyr)
library(tidyr)
library(ggiraph)
library(Rcpp)
library(patchwork)

#path to allThingsPheWAS/scripts
setwd("/atlasview/scripts")
home_res <- '/Users/ana/OneDrive - University College London/disease_atlas_TRE_results_shared'

getwd()

source("atlasview_MM_forest_fun.R")

###############################################################################

#speciality colors from lkp
my_colors <- read.csv(file = 'lkp_spe_col.csv', header = TRUE)
my_colors <- my_colors%>% filter(speciality != 'GMC')

my_colors$speciality
my_cols <- my_colors$color
names(my_cols) <- my_colors$speciality
colScale <- scale_color_manual(values=my_cols)

###############################################################################

#read full MM res in vis format
path_file_MM_res <- paste(home_res, "/Asif/vis/atlasview/MM_for_circo_network_vis_25052023.csv", sep = '')

MM_res <- fread(file=path_file_MM_res)
MM_res <- MM_res %>% filter(speciality_index_dis != 'GMC')

###############################################################################

#N of diseases and specialities 
path_file_M2 <- paste(home_res, "/Asif/vis/atlasview/MM_2_n_Feb03_25052023.csv", sep = '')

n_dis_spe <- fread(file = path_file_M2)

###############################################################################


#all specialities in results
all_spe <- unique(MM_res$speciality_index_dis)
  
#plots 
for (spe_index in all_spe){
  
  print(spe_index)
  
  #select results in speciality
  MM_res_spe <- MM_res  %>% filter(speciality_index_dis == spe_index)
  
  #all phecodes in the speciality
  phe_index_dis <- unique(MM_res_spe$phecode_index_dis)
  
  print(phe_index_dis)
  
  #select results and plot per phecode
  for (phe in phe_index_dis){
    
    print(phe)
    
    MM_res_spe_phe <- MM_res_spe %>% filter(phecode_index_dis == phe)
  
    
    df_plot <- caterpillar_prev_ratio_v5_view(MM_res_spe_phe, 
                                                     n_dis_spe, 
                                                     spe_index_dis=spe_index)
    
    
  }
  
}




