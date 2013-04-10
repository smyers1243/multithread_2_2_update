-- Execute second part of fingerprint trigger on biblio.record_entry.
-- This is not actual SQL but data used by the post_update_driver.pl.
-- That script will extract the line that returns the id range of 
-- the table and the rest executes the function with ranges of ids.

-- Both fringerprint scripts executed in 1 hours, 35 minutes, 8 seconds, 
-- 1,111,116 rows, four patitions, 500 rows per update

-- Get starting and ending ID from the update file
SELECT MAX(id), MIN(id) FROM biblio.record_entry;

-- Disable ALL trigger of this table (and re-enable them after update)
ALTER TABLE biblio.record_entry DISABLE TRIGGER ALL;

-- Execute part of the trigger with id ranges.
-- start_id and end_id are replaced by the post_update_driver script.
UPDATE biblio.record_entry 
   SET quality = biblio.extract_quality( marc, 'eng', 'BKS' ) 
 WHERE id IN (
		SELECT id 
		  FROM biblio.record_entry 
		 WHERE id >= ~start_id~ AND id < ~end_id~
);