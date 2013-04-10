CREATE INDEX metabib_full_rec_isxn_caseless_idx
  ON metabib.real_full_rec
  USING btree
  (lower(value) COLLATE pg_catalog."default")
  WHERE tag = ANY (ARRAY['020'::bpchar, '022'::bpchar, '024'::bpchar]);
  
