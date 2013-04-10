CREATE INDEX "fki_normalized_subject_to_ subject_field_entry_FK"
  ON metabib.normalized_subject_field_entry
  USING btree
  (id);