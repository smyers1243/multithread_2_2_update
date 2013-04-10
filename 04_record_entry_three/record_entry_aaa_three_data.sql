-- Execute third part of aaa trigger on biblio.record_entry.
-- This is not actual SQL but data used by the post_update_driver.pl.
-- That script will extract the CREATE and DROP FUNCTION lines, the
-- line that returns the total rows of the table, and the line that
-- executes the function with offsets and limits.

-- Executed in 2 hours, 36 minutes, 53 seconds

-- Create a wrapper function for the third trigger of biblio.record_entry.
-- Must start with CREATE [OR REPLACE] FUNCTION and end with $$ LANGUAGE.
CREATE OR REPLACE FUNCTION biblio.wrap_record_entry_aaa_three(start_id BIGINT, end_id BIGINT) 
RETURNS void AS $$
DECLARE
	rec RECORD;
BEGIN
	FOR rec IN SELECT id, marc FROM biblio.record_entry WHERE id >= start_id AND id < end_id
	LOOP
		PERFORM biblio.record_entry_aaa_three( rec.id, rec.marc );
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- The SQL that will drop the function
DROP FUNCTION IF EXISTS biblio.wrap_record_entry_aaa_three(BIGINT, BIGINT);

-- Get min and max id from update file
SELECT MAX(id), MIN(id) FROM biblio.record_entry;

-- Disable ALL trigger of this table (and re-enable them after update)
ALTER TABLE biblio.record_entry DISABLE TRIGGER ALL;

-- Execute part of the trigger with start and end id.
-- These are replaced by the post_update_driver script.
SELECT biblio.wrap_record_entry_aaa_three(~start_id~, ~end_id~);