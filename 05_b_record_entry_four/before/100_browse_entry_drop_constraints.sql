ALTER TABLE metabib.browse_entry_def_map DROP CONSTRAINT browse_entry_def_map_pkey;
ALTER TABLE metabib.browse_entry_def_map DROP CONSTRAINT browse_entry_def_map_def_fkey;
ALTER TABLE metabib.browse_entry_def_map DROP CONSTRAINT browse_entry_def_map_entry_fkey;
ALTER TABLE metabib.browse_entry_def_map DROP CONSTRAINT browse_entry_def_map_source_fkey;