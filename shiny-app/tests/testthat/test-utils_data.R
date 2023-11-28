test_that("get_atlasview_data() returns mock data when ATLASVIEW_DATA_PATH not set", {
  withr::local_envvar(ATLASVIEW_DATA_PATH = "")
  expect_warning(test_data <- get_atlasview_data(), "defaulting to `atlasview_mock_data`")
  expect_identical(test_data, atlasview_mock_data)
})
