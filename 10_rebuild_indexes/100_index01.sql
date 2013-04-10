CREATE INDEX metabib_author_field_entry_index_vector_idx
  ON metabib.author_field_entry
  USING gist
  (index_vector);
