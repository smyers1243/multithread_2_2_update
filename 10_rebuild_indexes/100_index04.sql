  CREATE INDEX metabib_keyword_field_entry_index_vector_idx
  ON metabib.keyword_field_entry
  USING gist
  (index_vector);
