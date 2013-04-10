-- Execute c_contains trigger on biblio.record_entry.
-- This is not actual SQL but data used by the post_update_driver.pl.
-- That script will extract the CREATE and DROP FUNCTION lines, the
-- line that returns the id ranges of the table, and the line that
-- executes the function with ranges of ids.

-- Executes in 56 minutes, 30 seconds, 1,111,116 rows, four partitions, 500 rows per update
-- Executes in ...

-- Create a wrapper function for the c_contains trigger of biblio.record_entry.
-- Must start with CREATE [OR REPLACE] FUNCTION and end with $$ LANGUAGE.
CREATE OR REPLACE FUNCTION biblio.wrap_record_entry_c_contains(start_id BIGINT, end_id BIGINT) 
RETURNS void AS $$
DECLARE
	rec RECORD;
BEGIN
	FOR rec IN SELECT marc, id, owner FROM biblio.record_entry WHERE id >= start_id AND id < end_id
	LOOP
		PERFORM biblio.record_entry_c_contains(rec.marc, rec.id, rec.owner);
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- The SQL that will drop the function
DROP FUNCTION IF EXISTS biblio.wrap_record_entry_c_contains(BIGINT, BIGINT);

-- Get starting and ending ID from the update file
SELECT MAX(id), MIN(id) FROM biblio.record_entry;

-- Disable ALL trigger of this table (and re-enable them after update)
ALTER TABLE biblio.record_entry DISABLE TRIGGER ALL;

-- Execute part of the trigger with id ranges.
-- start_id and end_id are replaced by the post_update_driver script.
SELECT biblio.wrap_record_entry_c_contains(~start_id~, ~end_id~);