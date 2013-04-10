CREATE INDEX metabib_series_field_entry_source_idx
  ON metabib.series_field_entry
  USING btree
  (source);