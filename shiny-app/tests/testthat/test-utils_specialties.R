test_that("get_index_diseases() returns empty list when no index diseases found", {
  mock_diseases <- data.frame(specialty_code = LETTERS[1:5])
  expect_length(get_index_diseases(mock_diseases, "ZZZ"), 0)
})

test_that("get_index_diseases() output has right format", {
  disease_codes <- paste0("a_", seq_len(6))
  phenotypes <- paste("disease", letters[1:6])
  mock_diseases <- data.frame(
    phecode_index_dis = disease_codes,
    phenotype_index_dis = phenotypes,
    specialty_code = rep(LETTERS[1:2], each = 3)
  )
  
  out <- get_index_diseases(mock_diseases, "A")
  expect_type(out, "list")
  expect_named(out, phenotypes[1:3])
  expect_contains(out, disease_codes[1:3])
})
