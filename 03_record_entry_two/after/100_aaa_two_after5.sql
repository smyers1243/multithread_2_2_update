CREATE INDEX metabib_full_rec_record_idx
  ON metabib.real_full_rec
  USING btree
  (record);
  
