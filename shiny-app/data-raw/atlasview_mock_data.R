## code to prepare `atlasview_mock_data` dataset goes here
library(dplyr)

## Load the real Atlasview data from its expected location
local_atlasview_data <- function() {
  withr::local_envvar(c("ATLASVIEW_DATA_PATH" = "../../atlasview-data/"))
  atlasview:::get_atlasview_data()
}

local_data <- local_atlasview_data()
random_seed <- 42

## Co-occurring diseases and patient counts data
MM_for_circos_network <- local_data$MM_res
MM_2_n <- local_data$n_dis_spe


# Randomise co-occurring diseases data --------------------------------------------------------

# Shuffle the prevalence, prev_ratios and shuffled co-occurring diseases and add some noise
withr::with_seed(random_seed, {
  MM_for_circos_network$prevalence <- jitter(sample(MM_for_circos_network$prevalence))
  MM_for_circos_network$prev_ratio <- jitter(sample(MM_for_circos_network$prev_ratio))
})
MM_for_circos_network$prev_ratio[MM_for_circos_network$prev_ratio < 0.3] <- 0.3   # Make prev_ratio look sensible

# Shuffle the co-occurring diseases
shuffled_cooc <- select(MM_for_circos_network, cooc_dis, phenotype_cooccurring_dis, specialty_cooccurring_dis)
withr::with_seed(random_seed, {
  shuffled_cooc <-  slice_sample(shuffled_cooc, prop = 1)
})

# Replace the columns in the data set with shuffled versions
MM_for_circos_network <- mutate(MM_for_circos_network,
  cooc_dis = shuffled_cooc$cooc_dis,
  phenotype_cooccurring_dis = shuffled_cooc$phenotype_cooccurring_dis,
  specialty_cooccurring_dis = shuffled_cooc$specialty_cooccurring_dis
)

# Pick some random specialties
specialties <- withr::with_seed(random_seed,
  sample(unique(MM_for_circos_network$specialty_index_dis), 3)
)

# Extract rows for selected specialties
MM_for_circos_network <- filter(MM_for_circos_network, specialty_index_dis %in% specialties)

# Sample three rows for each index disease
MM_for_circos_network <- withr::with_seed(random_seed,
  slice_sample(
    group_by(MM_for_circos_network, phecode_index_dis),
    n = 3
  )
)
MM_for_circos_network <- ungroup(MM_for_circos_network)


# Randomise patient count data ----------------------------------------------------------------

# Shuffle the index disease columns
MM_2_n$index_dis <- withr::with_seed(random_seed, sample(MM_2_n$index_dis))

# Shuffle and add noise to all the numeric columns
withr::with_seed(random_seed, {
  MM_2_n <- mutate(MM_2_n, 
    across(where(is.numeric), ~ jitter(sample(.x))),
    across(where(is.numeric), ~ abs(as.integer(.x)))
  )
})

# We only need index diseases we sampled for MM_for_circos_network, above
MM_2_n <- filter(MM_2_n, index_dis %in% MM_for_circos_network$phecode_index_dis)


# Create new copy with randomised data --------------------------------------------------------

atlasview_mock_data <- local_data
atlasview_mock_data$MM_res <- MM_for_circos_network
atlasview_mock_data$n_dis_spe <- MM_2_n

usethis::use_data(atlasview_mock_data, overwrite = TRUE)
