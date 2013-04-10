CREATE INDEX metabib_series_field_entry_index_vector_idx
  ON metabib.series_field_entry
  USING gist
  (index_vector);