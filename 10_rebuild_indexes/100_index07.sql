CREATE INDEX "fki_normalized_author_to_ author_field_entry_FK"
  ON metabib.normalized_author_field_entry
  USING btree
  (id);
