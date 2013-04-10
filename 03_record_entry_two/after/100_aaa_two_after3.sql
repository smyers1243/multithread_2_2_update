CREATE INDEX metabib_full_rec_index_vector_idx
  ON metabib.real_full_rec
  USING gist
  (index_vector);
  
