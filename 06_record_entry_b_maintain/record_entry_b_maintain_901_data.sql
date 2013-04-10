-- Execute the b_maintain_901 trigger on biblio.record_entry.
-- This is not actual SQL but data used by the post_update_driver.pl.
-- That script will extract the CREATE and DROP FUNCTION lines, the
-- line that returns the total rows of the table, and the line that
-- executes the function with offsets and limits.

-- The function record_entry_b_maintain_901() is not part of the standard
-- Evergreen code, but should be created manually first by running
-- the script record_entry_b_maintain_901_create.sql.  It can be deleted after
-- post_update_driver.pl is finished.

-- Executed 1,111,116 rows in 37 minutes, 35 seconds

-- Create a wrapper function for the third trigger of biblio.record_entry.
-- Must start with CREATE [OR REPLACE] FUNCTION and end with $$ LANGUAGE.
CREATE OR REPLACE FUNCTION biblio.wrap_record_entry_b_maintain_901(start_id INT, end_id INT) 
RETURNS void AS $$
DECLARE
	rec RECORD;
BEGIN
	FOR rec IN SELECT id, marc, tcn_value, tcn_source, owner, share_depth FROM biblio.record_entry WHERE id >= start_id AND id < end_id 
	LOOP
		PERFORM biblio.record_entry_b_maintain_901( rec.id::BIGINT, rec.marc::TEXT, rec.tcn_value::TEXT, rec.tcn_source::TEXT, rec.owner::INTEGER, rec.share_depth::INTEGER );
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- The SQL that will drop the function
DROP FUNCTION IF EXISTS biblio.wrap_record_entry_b_maintain_901(INT, INT);

-- Get starting and ending ID from update file
SELECT MAX(id), MIN(id) FROM biblio.record_entry;

-- Disable ALL trigger of this table (and re-enable them after update)
ALTER TABLE biblio.record_entry DISABLE TRIGGER ALL;

-- Execute part of the trigger with offsets and limits.
-- Offset and limit are replaced by the post_update_driver script.
SELECT biblio.wrap_record_entry_b_maintain_901(~start_id~, ~end_id~);