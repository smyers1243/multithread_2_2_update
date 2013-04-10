CREATE INDEX metabib_full_rec_02x_tag_subfield_lower_substring
  ON metabib.real_full_rec
  USING btree
  (tag COLLATE pg_catalog."default", subfield COLLATE pg_catalog."default", lower("substring"(value, 1, 1024)) COLLATE pg_catalog."default")
  WHERE tag = ANY (ARRAY['020'::bpchar, '022'::bpchar, '024'::bpchar]);
  
