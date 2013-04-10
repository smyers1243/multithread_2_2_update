CREATE INDEX metabib_full_rec_tag_record_idx
  ON metabib.real_full_rec
  USING btree
  (tag COLLATE pg_catalog."default", record);
  
