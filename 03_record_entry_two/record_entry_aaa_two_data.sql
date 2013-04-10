-- Execute second part of aaa trigger on biblio.record_entry.
-- This is not actual SQL but data used by the post_update_driver.pl.
-- That script will extract the CREATE and DROP FUNCTION lines, the
-- line that returns the total rows of the table, and the line that
-- executes the function with starting and ending ids.

-- Executed in 3 hours, 29 minutes, 0 seconds for 1,111,116 rows, six partitions, 500 rows per update

-- Create a wrapper function for the second trigger of biblio.record_entry.
-- Must start with CREATE [OR REPLACE] FUNCTION and end with $$ LANGUAGE.

--ASSUMES A TRUNCATE HAS TAKEN PLACE.

CREATE OR REPLACE FUNCTION biblio.wrap_record_entry_aaa_two(start_id BIGINT, end_id BIGINT) 
RETURNS void AS $$
DECLARE
	rec RECORD;
BEGIN
	FOR rec IN SELECT id FROM biblio.record_entry WHERE id >= start_id AND id < end_id
	LOOP
		INSERT INTO metabib.real_full_rec (record, tag, ind1, ind2, subfield, value)
            SELECT record, tag, ind1, ind2, subfield, value FROM biblio.flatten_marc( rec.id );
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- The SQL that will drop the function
DROP FUNCTION IF EXISTS biblio.wrap_record_entry_aaa_two(BIGINT, BIGINT);

-- Get starting end ending ID from the update table
SELECT MAX(id), MIN(id) FROM biblio.record_entry;

-- Disable ALL trigger of this table (and re-enable them after update)
ALTER TABLE biblio.record_entry DISABLE TRIGGER ALL;

-- Execute part of the trigger with offsets and limits.
-- Offset and limit are replaced by the post_update_driver script.
SELECT biblio.wrap_record_entry_aaa_two(~start_id~, ~end_id~);