CREATE INDEX metabib_subject_field_entry_source_idx
  ON metabib.subject_field_entry
  USING btree
  (source);