CREATE INDEX "fki_normalized_title_to_ title_field_entry_FK"
  ON metabib.normalized_title_field_entry
  USING btree
  (id);