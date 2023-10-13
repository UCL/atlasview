#' @importFrom rlang .data
caterpillar_plot <- function(caterpillar_data, median_counts, specialty_colours) {
  colScale <- scale_color_manual(values = specialty_colours)

  # params plots margins
  t <- 1.5
  r <- 1
  b <- 0.1
  l <- 0.2

  caterpillar_data <- dplyr::arrange(caterpillar_data, dplyr::desc(.data$prev_ratio))

  # phenotype and phecode of index disease (after sorting)
  phenotype <- caterpillar_data$phenotype_index_dis[1]
  phe <- caterpillar_data$phecode_index_dis[1]

  # not in plots
  caterpillar_data <- dplyr::filter(caterpillar_data, .data$phecode_index_dis != .data$cooc_dis)

  # subset if there is long list
  if (nrow(caterpillar_data) > 50) {
    caterpillar_data <- head(caterpillar_data, 50)
  }

  # index for plotting
  caterpillar_data$id <- seq(nrow(caterpillar_data), 1)

  # median_n
  median_counts <- dplyr::filter(median_counts, .data$index_dis == phe)
  median_n_dis <- median_counts$median_n_dis
  median_n_spe <- median_counts$median_n_spe
  n_cases_index_dis <- median_counts$n_indiv_index_dis_m_r

  # title
  phenotype_title <- stringr::str_wrap(phenotype, width = 80)
  plot_title_str <- paste("Index: ", phenotype_title, "\n",
    "N = ", n_cases_index_dis,
    ", Median N Dis = ", median_n_dis,
    " , Median N Spec = ", median_n_spe,
    sep = ""
  )
  
  # Initialize plotting variables
  # Avoids 'no visible binding for global variable' in R CMD check
  prevalence <- specialty_cooccurring_dis <- id <- NULL
  prev_ratio <- ci_left_prev_ratio <- ci_right_prev_ratio <- NULL

  # prevalence of co-occ disease in index disease
  p1 <- caterpillar_prevalence_plot(caterpillar_data) +
    theme_minimal() +
    theme(
      legend.position = c(.7, .5),
      legend.title = element_blank(),
      legend.text = element_text(size = 10),
      axis.text.y = element_text(size = 15),
      axis.title.y = element_blank(),
      plot.margin = unit(c(t, r, b, l), "lines"),
      axis.line.x = element_line(colour = "grey"),
      axis.text.x = element_text(size = 15),
      axis.title.x = element_text(size = 15),
      plot.title = element_text(size = 20, hjust = 1)
    ) +
    scale_fill_manual(values = specialty_colours) +
    theme(legend.position = "none")

  # prev ratio
  p3 <- ggplot(
    caterpillar_data,
    aes(
      x = prev_ratio,
      xmin = ci_left_prev_ratio, xmax = ci_right_prev_ratio,
      col = as.factor(specialty_cooccurring_dis), y = as.factor(id)
    )
  ) +
    geom_errorbarh(height = 0) +
    geom_point(shape = 15, size = 2) +
    geom_vline(xintercept = 1, linetype = "dashed", color = "black", linewidth = 0.75) +
    scale_x_log10() +
    labs(y = NULL) +
    theme_minimal() +
    theme(
      legend.position = "none",
      legend.title = element_blank(),
      legend.text = element_text(size = 10),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = 15),
      axis.title.x = element_text(size = 15),
      axis.title.y = element_blank(),
      plot.margin = unit(c(t, 2, b, l), "lines"),
      axis.line.x = element_line(colour = "grey"),
      plot.title = element_text(size = 20, hjust = 1)
    ) +
    xlab("Prevalence ratio") +
    colScale

  ### combine:
  patchwork::wrap_plots(p1, p3, nrow = 1) +
    patchwork::plot_annotation(
      plot_title_str,
      theme = theme(plot.title = element_text(size = 20, hjust = 0.5))
    )
}


caterpillar_prevalence_plot <- function(caterpillar_data) {
  # Initialize plotting variables
  # Avoids 'no visible binding for global variable' in R CMD check
  prevalence <- specialty_cooccurring_dis <- phenotype_cooccurring_dis <- NULL
  
  ggplot(caterpillar_data,
    aes(x = phenotype_cooccurring_dis, y = prevalence, fill = specialty_cooccurring_dis)
  ) +
    geom_col(width = 0.5) +
    coord_flip(ylim = c(0, 100)) +
    labs(x = NULL, y = "Prevalence (%)", fill = NULL)
}

caterpillar_prevalence_ratio_plot <- function(caterpillar_data) {
  # Initialize plotting variables
  # Avoids 'no visible binding for global variable' in R CMD check
  prev_ratio <- specialty_cooccurring_dis <- phenotype_cooccurring_dis <- NULL
  
  ggplot(caterpillar_data,
    aes(x = prev_ratio, y = phenotype_cooccurring_dis, col = specialty_cooccurring_dis)) +
    geom_point(shape = 15, size = 2) +
    geom_vline(xintercept = 1, linetype = "dashed", color = "black", linewidth = 0.75) +
    scale_x_log10() +
    labs(x = "Prevalence ratio", y = NULL, color = NULL)
}

