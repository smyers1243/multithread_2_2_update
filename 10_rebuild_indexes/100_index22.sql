CREATE INDEX metabib_series_field_entry_value_idx
  ON metabib.series_field_entry
  USING btree
  ("substring"(value, 1, 1024) COLLATE pg_catalog."default")
  WHERE index_vector = ''::tsvector;