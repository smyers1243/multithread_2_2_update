CREATE INDEX full_rec_url_tpo_idx
  ON metabib.real_full_rec
  USING btree
  (value COLLATE pg_catalog."default" text_pattern_ops)
  WHERE tag = '856'::bpchar AND subfield = 'u'::text;

