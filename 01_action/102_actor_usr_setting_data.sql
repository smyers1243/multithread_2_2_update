-- Insert a row for each usr into the actor.usr_setting table with 
-- a default_hold_pickup_location the same as the home_ou.

-- Executes in 00 hours, 07 minutes, 33 seconds

-- Get id range from the update file
SELECT MAX(id), MIN(id) FROM actor.usr;

-- Execute the update with a range of ids.
-- start_id and end_id are replaced by the post_update_driver script.
INSERT INTO actor.usr_setting (usr, name, value)
SELECT au.id, 'opac.default_pickup_location', '"' || au.home_ou::text || '"' 
FROM actor.usr AS au
WHERE au.id >= ~start_id~ AND au.id < ~end_id~;