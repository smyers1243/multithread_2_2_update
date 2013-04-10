CREATE INDEX metabib_full_rec_value_tpo_idx
  ON metabib.real_full_rec
  USING btree
  ("substring"(value, 1, 1024) COLLATE pg_catalog."default" text_pattern_ops);