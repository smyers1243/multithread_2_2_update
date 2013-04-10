CREATE INDEX metabib_keyword_field_entry_source_idx
  ON metabib.keyword_field_entry
  USING btree
  (source);
