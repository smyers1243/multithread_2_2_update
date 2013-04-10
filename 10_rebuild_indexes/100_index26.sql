CREATE INDEX metabib_title_field_entry_index_vector_idx
  ON metabib.title_field_entry
  USING gist
  (index_vector);