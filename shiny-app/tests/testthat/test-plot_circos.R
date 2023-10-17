suppressWarnings({
  test_data <- get_atlasview_data()
})
test_MM_res <- test_data$MM_res

withr::with_seed(20231017, {
  select_specialty <- sample(unique(test_MM_res$specialty_code), 1)
  select_index_disease <- sample(get_index_diseases(test_data$index_diseases, select_specialty), 1)
})

index_disease_patient_count <- get_patient_counts(test_data$n_dis_spe, select_index_disease)
cooccurring <- get_cooccurring_diseases(test_MM_res, select_index_disease)

test_that("circos_plot() produces consistent output", {
  p <- circos_plot(test_data$specialties, cooccurring, index_disease_patient_count, svg_filepath = NULL)
  vdiffr::expect_doppelganger("circos_plot", p)
})
