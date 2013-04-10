CREATE INDEX normalized_remove_insignificants_author_field_entry_gist_trgm
  ON metabib.normalized_author_field_entry
  USING gist
  (remove_insignificants(value) COLLATE pg_catalog."C" gist_trgm_ops);