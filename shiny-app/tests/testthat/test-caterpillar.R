test_data <- atlasview_mock_data
test_MM_res <- test_data$MM_res

withr::with_seed(20231013, {
  select_specialty <- sample(unique(test_MM_res$specialty_code), 1)
  select_index_disease <- sample(get_index_diseases(test_data$index_diseases, select_specialty), 1)
})

test_caterpillar_data <- get_cooccurring_diseases(test_data$MM_res,
  index_disease = select_index_disease, specialty = select_specialty
)

test_that("get_cooccurring_diseases() returns correct format for caterpillar plot", {
  expect_s3_class(test_caterpillar_data, "data.frame")
  expect_true(nrow(test_caterpillar_data) > 0)
  expect_true(ncol(test_caterpillar_data) > 0)
  
  ## Need at least these names for caterpillar plot to work
  expected_names <- c(
    "prevalence", "specialty_cooccurring_dis", "prev_ratio",
    "ci_left_prev_ratio", "ci_right_prev_ratio"
  )
  expect_contains(names(test_caterpillar_data), expected_names)
})

test_that("caterpillar_prevalence_plot() produces consistent plot", {
  p <- caterpillar_prevalence_plot(test_caterpillar_data)
  vdiffr::expect_doppelganger("caterpillar_prevalence", p)
})

test_that("caterpillar_prevalence_ratio_plot() produces consistent plot", {
  p <- caterpillar_prevalence_ratio_plot(test_caterpillar_data)
  vdiffr::expect_doppelganger("caterpillar_prevalence_ratio", p)
})
