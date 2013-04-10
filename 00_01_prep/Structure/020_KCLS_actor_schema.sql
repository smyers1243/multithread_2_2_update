-- Actor Schema Inits
-- Put into script that will run after config_schema.  Depends on new config table.
--TODO: make sure config.usr_activity_type is being created
CREATE TABLE actor.usr_activity (
    id          BIGSERIAL   PRIMARY KEY,
    usr         INT         REFERENCES actor.usr (id) ON DELETE SET NULL,
    etype       INT         NOT NULL REFERENCES config.usr_activity_type (id),
    event_time  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--TRIGGERS for actor.stat_cat, DEPENDS on asset.stat_cat_check()
CREATE TRIGGER actor_stat_cat_sip_update_trigger
    BEFORE INSERT OR UPDATE ON actor.stat_cat FOR EACH ROW
    EXECUTE PROCEDURE actor.stat_cat_check();
CREATE TRIGGER asset_stat_cat_sip_update_trigger
    BEFORE INSERT OR UPDATE ON asset.stat_cat FOR EACH ROW
    EXECUTE PROCEDURE asset.stat_cat_check();
	
--TRIGGER utilizing function
CREATE TRIGGER proximity_update_tgr AFTER INSERT OR UPDATE OR DELETE ON actor.org_unit FOR EACH ROW EXECUTE PROCEDURE actor.org_unit_prox_update ();

--ADD TRIGGERS DEPENDANT on actor.au_updated
CREATE TRIGGER au_update_trig
	BEFORE INSERT OR UPDATE ON actor.usr
	FOR EACH ROW EXECUTE PROCEDURE actor.au_updated();

-- remove transient activity entries on insert of new entries: Trigger remove_transient_usr_activity uses
CREATE OR REPLACE FUNCTION actor.usr_activity_transient_trg () RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM actor.usr_activity act USING config.usr_activity_type atype
        WHERE atype.transient AND 
            NEW.etype = atype.id AND
            act.etype = atype.id AND
            act.usr = NEW.usr;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;


--Trigger using function above
CREATE TRIGGER remove_transient_usr_activity
    BEFORE INSERT ON actor.usr_activity
    FOR EACH ROW EXECUTE PROCEDURE actor.usr_activity_transient_trg();

-- given a set of activity criteria, finds the best
-- activity type and inserts the activity entry
CREATE OR REPLACE FUNCTION actor.insert_usr_activity (
        usr INT,
        ewho TEXT, 
        ewhat TEXT, 
        ehow TEXT
    ) RETURNS SETOF actor.usr_activity AS $$
DECLARE
    new_row actor.usr_activity%ROWTYPE;
BEGIN
    SELECT id INTO new_row.etype FROM actor.usr_activity_get_type(ewho, ewhat, ehow);
    IF FOUND THEN
        new_row.usr := usr;
        INSERT INTO actor.usr_activity (usr, etype) 
            VALUES (usr, new_row.etype)
            RETURNING * INTO new_row;
        RETURN NEXT new_row;
    END IF;
END;
$$ LANGUAGE plpgsql;

--CHECK DEPENDENCIES, if none move to 005_actor
CREATE TRIGGER log_ous_change
    BEFORE INSERT OR UPDATE ON actor.org_unit_setting
    FOR EACH ROW EXECUTE PROCEDURE ous_change_log();
	
CREATE TRIGGER log_ous_del
    BEFORE DELETE ON actor.org_unit_setting
    FOR EACH ROW EXECUTE PROCEDURE ous_delete_log();