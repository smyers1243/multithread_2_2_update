CREATE INDEX metabib_title_field_entry_source_idx
  ON metabib.title_field_entry
  USING btree
  (source);