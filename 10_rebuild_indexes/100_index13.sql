CREATE INDEX normalized_series_field_entry_gist_trgm
  ON metabib.normalized_series_field_entry
  USING gist
  (value COLLATE pg_catalog."C" gist_trgm_ops);