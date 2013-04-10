CREATE INDEX metabib_subject_field_entry_index_vector_idx
  ON metabib.subject_field_entry
  USING gist
  (index_vector);