CREATE INDEX metabib_author_field_entry_source_idx
  ON metabib.author_field_entry
  USING btree
  (source);
