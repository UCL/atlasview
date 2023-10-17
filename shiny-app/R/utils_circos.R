get_patient_counts <- function(all_patient_counts, index_disease) {
  which_index_disease <- all_patient_counts$index_dis == index_disease
  all_patient_counts$n_indiv_index_dis_m_r[which_index_disease]
}
