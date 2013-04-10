CREATE INDEX metabib_full_rec_tnf_idx
  ON metabib.real_full_rec
  USING btree
  (record, tag COLLATE pg_catalog."default", subfield COLLATE pg_catalog."default")
  WHERE tag = 'tnf'::bpchar AND subfield = 'a'::text;
  
