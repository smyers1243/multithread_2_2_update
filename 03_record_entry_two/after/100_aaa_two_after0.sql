CREATE INDEX full_rec_isbn_tpo_idx
  ON metabib.real_full_rec
  USING btree
  ("substring"(value, 1, 1024) COLLATE pg_catalog."default" text_pattern_ops)
  WHERE tag = ANY (ARRAY['020'::bpchar, '024'::bpchar]);
  

  