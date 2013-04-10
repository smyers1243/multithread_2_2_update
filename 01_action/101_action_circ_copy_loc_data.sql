-- Execute copy location on action.circulation.
-- This is not actual SQL but data used by the post_update_driver.pl.
-- That script will extract the line that returns the id range of 
-- the table and the rest executes the function with id ranges.

-- Executes in 7 hours, 4 minutes, 6 seconds

-- Get id range from the update file
SELECT MAX(id), MIN(id) FROM asset.copy;

-- Disable all trigger of this table (and re-enable them after update)
ALTER TABLE action.circulation DISABLE TRIGGER ALL;

-- Execute the update with a range of ids.
-- start_id and end_id are replaced by the post_update_driver script.
UPDATE action.circulation circ 
   SET copy_location = ac.location 
  FROM asset.copy AS ac 
 WHERE ac.id = circ.target_copy AND ac.id >= ~start_id~ AND ac.id < ~end_id~;	