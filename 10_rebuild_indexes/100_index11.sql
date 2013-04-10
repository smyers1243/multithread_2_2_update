CREATE INDEX "fki_normalized_series_to_ series_field_entry_FK"
  ON metabib.normalized_series_field_entry
  USING btree
  (id);