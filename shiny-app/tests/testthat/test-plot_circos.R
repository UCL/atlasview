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

test_that("circos_plot() produces SVG file when `svg_filepath` defined", {
  tmp_file <- withr::local_tempfile(fileext = ".svg")
  circos_plot(test_data, select_index_disease, svg_filepath = tmp_file)
  expect_true(file.exists(tmp_file))
})

test_that("circos_plot() does not produce warning messages", {
  expect_no_message({
    circos_plot(test_data, select_index_disease, svg_filepath = NULL)
  })
})
