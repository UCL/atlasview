# This script takes real `MM_for_circos_network_vis` and `MM_2_n` files and 
# produces reduced, shuffled, data for development
library(magrittr)

# Filepaths to real data files
MM_for_circos_network_filepath = '../../atlasview-data/MM_for_circo_network_vis.csv'
MM_2_n_filepath = '../../atlasview-data/MM_2_n.csv'


MM_for_circos_network <- read.csv(MM_for_circos_network_filepath)

# Shuffle the prevalence, prev_ratios and shuffled co-occurring diseases and add some noise TODO: using dplyr?
MM_for_circos_network$prevalence <- jitter(sample(MM_for_circos_network$prevalence))
MM_for_circos_network$prev_ratio <- jitter(sample(MM_for_circos_network$prev_ratio))
MM_for_circos_network$prev_ratio[MM_for_circos_network$prev_ratio < 0.3] <- 0.3   # Make prev_ratio look sensible

# Shuffle the co-occurring diseases
shuffled_cooc <- MM_for_circos_network %>% dplyr::select(cooc_dis, phenotype_cooccurring_dis, specialty_cooccurring_dis) %>% dplyr::sample_frac()

# Replace the columns in the data set with shuffled versions
MM_for_circos_network <- MM_for_circos_network %>%
  dplyr::mutate(cooc_dis = shuffled_cooc$cooc_dis, 
                phenotype_cooccurring_dis = shuffled_cooc$phenotype_cooccurring_dis, 
                specialty_cooccurring_dis = shuffled_cooc$specialty_cooccurring_dis)

# Pick some specialties
specialties <- MM_for_circos_network %>% dplyr::select(specialty_index_dis) %>% dplyr::distinct() %>% dplyr::sample_n(3) %>% dplyr::pull()

# Extract rows for selected specialties
MM_for_circos_network <- MM_for_circos_network %>% 
  dplyr::filter(specialty_index_dis %in% specialties)

# Sample three rows for each index disease
MM_for_circos_network <- MM_for_circos_network %>%
  dplyr::group_by(phecode_index_dis) %>%
  dplyr::slice_sample(n=3)

# Save the file
write.csv(MM_for_circos_network, '../deployment/atlasview-data/MM_for_circo_network_vis.csv', row.names = FALSE)


# Do the same for MM_2_n
MM_2_n <- read.csv(MM_2_n_filepath)

# Shuffle the index disease columns
MM_2_n$index_dis <- sample(MM_2_n$index_dis)

# Shuffle and add noise to all the numeric columns
MM_2_n_columns <- colnames(MM_2_n)
for (col in MM_2_n_columns[!MM_2_n_columns %in% 'index_dis']) {
  MM_2_n[col] <- jitter(sample(MM_2_n[[col]]))
  MM_2_n[col] <- abs(as.integer(MM_2_n[[col]]))
}

# We only need index diseases we sampled for MM_for_circos_network, above
MM_2_n <- MM_2_n %>% dplyr::filter(MM_2_n$index_dis %in% MM_for_circos_network$phecode_index_dis)

write.csv(MM_2_n, '../deployment/atlasview-data/MM_2_n.csv', row.names = FALSE)
