-- Execute create date for any item with circs on asset.copy.
-- This is not actual SQL but data used by the post_update_driver.pl.
-- That script will extract the line that returns the id range of 
-- the table and the rest executes the function with id ranges.

-- Executes in 1 hours, 16 minutes, 56 seconds, four partitions, 500 rows

-- Get id range from the update file
SELECT MAX(id), MIN(id) FROM extend_reporter.full_circ_count WHERE circ_count > 0;

-- Disable all trigger of this table (and re-enable them after update)
ALTER TABLE action.circulation DISABLE TRIGGER ALL;

-- Execute the update with a range of ids.
-- start_id and end_id are replaced by the post_update_driver script.
UPDATE asset.copy 
   SET active_date = create_date 
 WHERE id IN (
		SELECT id 
		  FROM extend_reporter.full_circ_count 
		 WHERE circ_count > 0 AND id >= ~start_id~ AND id < ~end_id~
);
