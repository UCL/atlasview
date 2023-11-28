test_that("parse_url() returns correct result", {
  out <- parse_url("?disease=foo$bar")
  expect_identical(out, list(specialty = "foo", disease = "bar"))
})

test_that("parse_url() returns NULL when 'disease' not present", {
  out <- parse_url("?foo")
  expect_null(out)
})

test_that("parse_url() returns NA for disease if no '$' in url", {
  out <- parse_url("?disease=foo&random=bar")
  expect_true(is.na(out[["disease"]]))
})
