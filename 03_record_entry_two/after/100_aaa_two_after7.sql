CREATE INDEX metabib_full_rec_tag_subfield_idx
  ON metabib.real_full_rec
  USING btree
  (tag COLLATE pg_catalog."default", subfield COLLATE pg_catalog."default");
  
