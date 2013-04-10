ALTER TABLE metabib.browse_entry_def_map
  ADD CONSTRAINT browse_entry_def_map_pkey PRIMARY KEY(id);
  
ALTER TABLE metabib.browse_entry_def_map
  ADD CONSTRAINT browse_entry_def_map_def_fkey FOREIGN KEY (def)
      REFERENCES config.metabib_field (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;
	  
ALTER TABLE metabib.browse_entry_def_map
  ADD CONSTRAINT browse_entry_def_map_entry_fkey FOREIGN KEY (entry)
      REFERENCES metabib.browse_entry (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;
	  
ALTER TABLE metabib.browse_entry_def_map
  ADD CONSTRAINT browse_entry_def_map_source_fkey FOREIGN KEY (source)
      REFERENCES biblio.record_entry (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;