-- Asset Schema Inits

-- FROM Function Script /start

DROP FUNCTION IF EXISTS asset.stat_cat_check();
CREATE OR REPLACE FUNCTION asset.stat_cat_check() RETURNS trigger AS $func$
DECLARE
    sipfield asset.stat_cat_sip_fields%ROWTYPE;
    use_count INT;
BEGIN
    IF NEW.sip_field IS NOT NULL THEN
        SELECT INTO sipfield * FROM asset.stat_cat_sip_fields WHERE field = NEW.sip_field;
        IF sipfield.one_only THEN
            SELECT INTO use_count count(id) FROM asset.stat_cat WHERE sip_field = NEW.sip_field AND id != NEW.id;
            IF use_count > 0 THEN
                RAISE EXCEPTION 'Sip field cannot be used twice';
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$func$ LANGUAGE PLPGSQL;

-- Used by Triggers
DROP FUNCTION IF EXISTS asset.acp_created();
CREATE OR REPLACE FUNCTION asset.acp_created()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.active_date IS NULL AND NEW.status IN (SELECT id FROM config.copy_status WHERE copy_active = true) THEN
        NEW.active_date := now();
    END IF;
    IF NEW.status_changed_time IS NULL THEN
        NEW.status_changed_time := now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- FROM Function Script /end

ALTER TABLE asset.copy
    ADD COLUMN active_date TIMESTAMP WITH TIME ZONE;
	
ALTER TABLE asset.stat_cat
    ADD COLUMN sip_field   CHAR(2) REFERENCES asset.stat_cat_sip_fields(field) ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED,
    ADD COLUMN sip_format  TEXT;

-- Archive Flag Columns
ALTER TABLE asset.stat_cat
    ADD COLUMN checkout_archive BOOL NOT NULL DEFAULT FALSE;

ALTER TABLE asset.copy_location
    ADD COLUMN checkin_alert BOOL NOT NULL DEFAULT FALSE;

CREATE TABLE asset.copy_location_group (
    id              SERIAL  PRIMARY KEY,
    name            TEXT    NOT NULL, -- i18n
    owner           INT     NOT NULL REFERENCES actor.org_unit (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    pos             INT     NOT NULL DEFAULT 0,
    top             BOOL    NOT NULL DEFAULT FALSE,
    opac_visible    BOOL    NOT NULL DEFAULT TRUE,
    CONSTRAINT lgroup_once_per_owner UNIQUE (owner,name)
);

CREATE TABLE asset.copy_location_group_map (
    id       SERIAL PRIMARY KEY,
    location    INT     NOT NULL REFERENCES asset.copy_location (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    lgroup      INT     NOT NULL REFERENCES asset.copy_location_group (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT  lgroup_once_per_group UNIQUE (lgroup,location)
);

--FROM Function script /start
CREATE OR REPLACE FUNCTION asset.acp_status_changed()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.status <> OLD.status AND NOT (NEW.status = 0 AND OLD.status = 7) THEN
        NEW.status_changed_time := now();
        IF NEW.active_date IS NULL AND NEW.status IN (SELECT id FROM config.copy_status WHERE copy_active = true) THEN
            NEW.active_date := now();
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

