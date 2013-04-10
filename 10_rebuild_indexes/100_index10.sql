CREATE INDEX "fki_normalized_keyword_to_ keyword_field_entry_FK"
  ON metabib.normalized_keyword_field_entry
  USING btree
  (id);