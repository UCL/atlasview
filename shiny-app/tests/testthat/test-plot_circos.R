suppressWarnings({
  test_data <- get_atlasview_data()
})
test_MM_res <- test_data$MM_res

withr::with_seed(20231017, {
  select_specialty <- sample(unique(test_MM_res$specialty_code), 1)
  select_index_disease <- sample(get_index_diseases(test_data$index_diseases, select_specialty), 1)
})


test_that("circos_plot() produces consistent output", {
  p <- function() circos_plot(test_data, select_index_disease, svg_filepath = NULL)
  vdiffr::expect_doppelganger("circos_plot", p)
})

test_that("circos_plot() resets circos params on exit", {
  old_params <- circos.par()
  circos_plot(test_data, select_index_disease, svg_filepath = NULL)
  new_params <- circos.par()
  expect_identical(new_params, old_params) 
})

test_that("circos_plot() produces consistent output with svg_filepath", {
  # p <- function() circos_plot(test_data, select_index_disease, svg_filepath = "test.svg")
  # vdiffr::expect_doppelganger("circos_plot", p)
})


specialty_codes <- test_data$specialties
cooccurring_diseases <- get_cooccurring_diseases(test_data$MM_res, select_index_disease)
test_that("circos_prev_ratio_track() does not produce any messages", {
  ## Set up circos plot
  withr::defer(circos.clear())
  circos_initialize_sectors(specialty_codes, cooccurring_diseases_per_specialty = 5)
  circos_long_names_track(cooccurring_diseases, cooccurring_diseases_per_specialty = 5)
  circos_short_names_track(cooccurring_diseases, specialty_codes, cooccurring_diseases_per_specialty = 5)

  expect_no_message({
    circos_prev_ratio_track(
      cooccurring_diseases, specialty_codes,
      prevalence_ratio_breaks = log(c(1, 5, 10, 50, 100, 500, 1000, 10000)),
      cooccurring_diseases_sector_bg_col = "#ECECEC",
      cooccurring_diseases_per_specialty = 5,
      sector_grid_lines_col = "#BFBFBF"
    )
  })
})

test_that("circos_prevalence_track() does not produce any messages", {
  ## Set up circos plot
  withr::defer(circos.clear())
  circos_initialize_sectors(specialty_codes, cooccurring_diseases_per_specialty = 5)
  circos_long_names_track(cooccurring_diseases, cooccurring_diseases_per_specialty = 5)
  circos_short_names_track(cooccurring_diseases, specialty_codes, cooccurring_diseases_per_specialty = 5)

  expect_no_message({
    circos_prevalence_track(
      cooccurring_diseases, specialty_codes,
      prevalence_breaks = log(c(1, 5, 10, 50, 100)),
      cooccurring_diseases_sector_bg_col = "#ECECEC",
      cooccurring_diseases_per_specialty = 5,
      sector_grid_lines_col = "#BFBFBF"
    )
  })
})
