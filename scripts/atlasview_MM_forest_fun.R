
#params plots margins 
t <- 1.5
r <- 1
b <- 0.1
l <- 0.2 


#df_prev: df with prev and prev_ratio for one index_disease 
#df_n: df_results median n diseases 
#spe_index_dis: speciality of index disease 
caterpillar_prev_ratio_v5_view <- function(df_prev, 
                                      df_n, 
                                      spe_index_dis, 
                                      blank_plot= FALSE){
  #sort
  df_prev <- df_prev %>% arrange(desc(prev_ratio))
  
  #phenotype and phecode of index disease (after sorting)
  phenotype <- df_prev$phenotype_index_dis[1]
  phe <- df_prev$phecode_index_dis[1]
  
  #not in plots
  df_prev <- filter(df_prev, phecode_index_dis != cooc_dis)
  
  # subset if there is long list
  if (nrow(df_prev)>50){
    df_prev <- df_prev[1:50,]
  }else{
    df_prev <- df_prev[1:nrow(df_prev),]
  }

  # index for plotting
  df_prev$id <- nrow(df_prev):1
  
  #median_n
  df_n_phe <- df_n %>% dplyr::filter(index_dis==phe)
  median_n_dis <- df_n_phe$median_n_dis
  median_n_spe <- df_n_phe$median_n_spe
  n_cases_index_dis <- df_n_phe$n_indiv_index_dis_m_r
  
  #title
  if (blank_plot == TRUE){
    plot_title_str <- ''
  }else{
    plot_title_str <- paste("Index: ", phenotype,
                            ", N = ", n_cases_index_dis,
                            ", Median N Dis = ", median_n_dis,
                            " , Median N Spec = ", median_n_spe, sep = '')
  }
  

  #plot ratio 
  max_y <- 10^7
  
  #max y axis in prev_ratio
  if (max(df_prev$prev_ratio) < 100){
    max_limit <- 100
  }else if (max(df_prev$prev_ratio) >= 100) {
    max_limit <- max(df_prev$prev_ratio)
  }
  
  #prevalence of co-occ disease in index disease
  p1 <- ggplot(df_prev,
               aes(y=prevalence,
                   fill=as.factor(speciality_cooccurring_dis),
                   x=as.factor(id)))+
    geom_bar(stat="identity",width=0.5)+
    coord_flip(ylim = c(0,100)) +
    theme_minimal() +
    theme(legend.position = c(.7, .5),
          legend.title=element_blank(),
          legend.text = element_text(size=10),
          axis.text.y = element_text(size=20),
          axis.title.y = element_blank(),
          plot.margin=unit(c(t,r,b,l),"lines"),
          axis.line.x = element_line(colour = "grey"),
          axis.text.x = element_text(size=20),
          axis.title.x = element_text(size=20),
          plot.title = element_text(size= 28, hjust = 1))+
    ylab("Prevalence (%)") +
    scale_x_discrete(labels=df_prev$phenotype_cooccurring_dis[nrow(df_prev):1]) +
    scale_fill_manual(values=my_cols) +
    theme(legend.position="none")

#prev ratio
p3 <-  ggplot(df_prev,
              aes(x=prev_ratio,
                  xmin=ci_left_prev_ratio,xmax=ci_right_prev_ratio,
                  col=as.factor(speciality_cooccurring_dis),y=as.factor(id)))+
  geom_errorbarh(height=0)+
  geom_point(shape=15, size = 4)+ 
  geom_vline(xintercept = 1, linetype="dashed", color = "black", linewidth=0.75) +
  scale_x_log10()+
  labs(y=NULL)+
  theme_minimal() +
  theme(legend.position="none",
        legend.title=element_blank(),
        legend.text = element_text(size=10),
        axis.text.y = element_blank(),
        axis.text.x = element_text(size=20),
        axis.title.x = element_text(size=20),
        axis.title.y = element_blank(),
        plot.margin=unit(c(t,2,b,l),"lines"),
        axis.line.x = element_line(colour = "grey"),
        plot.title = element_text(size= 28, hjust = 1)) +
  xlab("Prevalence ratio")+
  colScale


  ###combine:
  pl <- p1 + p3 + plot_annotation(plot_title_str,theme=theme(plot.title=element_text(size = 28, hjust=0.5)))

  #output file name
  ffplot_output <- paste("MMcaterpillar_", gsub("/", "", spe_index_dis), "_", phe,"_", gsub("/", "", phenotype), ".png", sep = '')

  #blank  - no title but keep phe in name - for reviews
  if (blank_plot == TRUE){
    ffplot_output <- paste(ffplot_output, "_blank.png", sep = '')
  }
  
  #save
  ggsave(pl, file=ffplot_output, width = 20, height=20, dpi=300, bg="white")
 
  #to check what we are plotting
  return(df_prev)
}

