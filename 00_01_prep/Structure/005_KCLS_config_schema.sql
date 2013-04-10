-- Config Schema Inits

DROP TABLE IF EXISTS config.db_patch_dependencies;
CREATE TABLE config.db_patch_dependencies (
  db_patch      TEXT PRIMARY KEY,
  supersedes    TEXT[],
  deprecates    TEXT[]
  );
  
DROP TABLE IF EXISTS config.barcode_completion;
CREATE TABLE config.barcode_completion (
    id          SERIAL  PRIMARY KEY,
    active      BOOL    NOT NULL DEFAULT true,
    org_unit    INT     NOT NULL REFERENCES actor.org_unit (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    prefix      TEXT,
    suffix      TEXT,
    length      INT     NOT NULL DEFAULT 0,
    padding     TEXT,
    padding_end BOOL    NOT NULL DEFAULT false,
    asset       BOOL    NOT NULL DEFAULT true,
    actor       BOOL    NOT NULL DEFAULT true
);

ALTER TABLE config.copy_status
    ADD COLUMN copy_active BOOL NOT NULL DEFAULT FALSE;

ALTER TABLE config.circ_matrix_weights
    ADD COLUMN item_age NUMERIC(6,2) NOT NULL DEFAULT 0.0;

ALTER TABLE config.hold_matrix_weights
    ADD COLUMN item_age NUMERIC(6,2) NOT NULL DEFAULT 0.0;

-- The two defaults above were to stop erroring on NOT NULL
-- Remove them here
ALTER TABLE config.circ_matrix_weights
    ALTER COLUMN item_age DROP DEFAULT;

ALTER TABLE config.hold_matrix_weights
    ALTER COLUMN item_age DROP DEFAULT;

ALTER TABLE config.circ_matrix_matchpoint
    ADD COLUMN item_age INTERVAL;

ALTER TABLE config.hold_matrix_matchpoint
    ADD COLUMN item_age INTERVAL;

DROP INDEX IF EXISTS config.ccmm_once_per_paramset;
CREATE UNIQUE INDEX ccmm_once_per_paramset ON config.circ_matrix_matchpoint (org_unit, grp, COALESCE(circ_modifier, ''), COALESCE(marc_type, ''), COALESCE(marc_form, ''), COALESCE(marc_bib_level,''), COALESCE(marc_vr_format, ''), COALESCE(copy_circ_lib::TEXT, ''), COALESCE(copy_owning_lib::TEXT, ''), COALESCE(user_home_ou::TEXT, ''), COALESCE(ref_flag::TEXT, ''), COALESCE(juvenile_flag::TEXT, ''), COALESCE(is_renewal::TEXT, ''), COALESCE(usr_age_lower_bound::TEXT, ''), COALESCE(usr_age_upper_bound::TEXT, ''), COALESCE(item_age::TEXT, '')) WHERE active;

DROP INDEX IF EXISTS config.chmm_once_per_paramset;
CREATE UNIQUE INDEX chmm_once_per_paramset ON config.hold_matrix_matchpoint (COALESCE(user_home_ou::TEXT, ''), COALESCE(request_ou::TEXT, ''), COALESCE(pickup_ou::TEXT, ''), COALESCE(item_owning_ou::TEXT, ''), COALESCE(item_circ_ou::TEXT, ''), COALESCE(usr_grp::TEXT, ''), COALESCE(requestor_grp::TEXT, ''), COALESCE(circ_modifier, ''), COALESCE(marc_type, ''), COALESCE(marc_form, ''), COALESCE(marc_bib_level, ''), COALESCE(marc_vr_format, ''), COALESCE(juvenile_flag::TEXT, ''), COALESCE(ref_flag::TEXT, ''), COALESCE(item_age::TEXT, '')) WHERE active;


ALTER TABLE config.z3950_source 
    ADD COLUMN use_perm INT REFERENCES permission.perm_list (id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

COMMENT ON COLUMN config.z3950_source.use_perm IS $$
If set, this permission is required for the source to be listed in the staff
client Z39.50 interface.  Similar to permission.grp_tree.application_perm.
$$;


CREATE TABLE config.org_unit_setting_type_log (
    id              BIGSERIAL   PRIMARY KEY,
    date_applied    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    org             INT         REFERENCES actor.org_unit (id),
    original_value  TEXT,
    new_value       TEXT,
    field_name      TEXT      REFERENCES config.org_unit_setting_type (name)
);


ALTER TABLE config.bib_source
ADD COLUMN can_have_copies BOOL NOT NULL DEFAULT TRUE;


-- Add some others before the UPDATE we are about to do breaks our ability to add columns
-- But we need this table first.
CREATE TABLE config.sms_carrier (
    id              SERIAL PRIMARY KEY,
    region          TEXT,
    name            TEXT,
    email_gateway   TEXT,
    active          BOOLEAN DEFAULT TRUE
);

-- add the new column
ALTER TABLE action.hold_request ADD COLUMN current_shelf_lib 
    INT REFERENCES actor.org_unit DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE action.hold_request ADD COLUMN sms_notify TEXT;
ALTER TABLE action.hold_request ADD COLUMN sms_carrier INT REFERENCES config.sms_carrier (id);
ALTER TABLE action.hold_request ADD CONSTRAINT sms_check CHECK (
    sms_notify IS NULL
    OR sms_carrier IS NOT NULL -- and implied sms_notify IS NOT NULL
);

ALTER TABLE config.standing_penalty ADD staff_alert BOOL NOT NULL DEFAULT FALSE;

ALTER TABLE config.copy_status
	  ADD COLUMN restrict_copy_delete BOOL NOT NULL DEFAULT FALSE;

ALTER TABLE config.metabib_field ADD COLUMN browse_field BOOLEAN DEFAULT TRUE NOT NULL;
ALTER TABLE config.metabib_field ADD COLUMN browse_xpath TEXT;

ALTER TABLE config.metabib_class ADD COLUMN bouyant BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE config.metabib_class ADD COLUMN restrict BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE config.metabib_field ADD COLUMN restrict BOOLEAN DEFAULT FALSE NOT NULL;


-- FIXME: add/check SQL statements to perform the upgrade
-- Limit groups for circ counting
CREATE TABLE config.circ_limit_group (
    id          SERIAL  PRIMARY KEY,
    name        TEXT    UNIQUE NOT NULL,
    description TEXT
);

-- Limit sets
CREATE TABLE config.circ_limit_set (
    id          SERIAL  PRIMARY KEY,
    name        TEXT    UNIQUE NOT NULL,
    owning_lib  INT     NOT NULL REFERENCES actor.org_unit (id) DEFERRABLE INITIALLY DEFERRED,
    items_out   INT     NOT NULL, -- Total current active circulations must be less than this. 0 means skip counting (always pass)
    depth       INT     NOT NULL DEFAULT 0, -- Depth count starts at
    global      BOOL    NOT NULL DEFAULT FALSE, -- If enabled, include everything below depth, otherwise ancestors/descendants only
    description TEXT
);

-- Linkage between matchpoints and limit sets
CREATE TABLE config.circ_matrix_limit_set_map (
    id          SERIAL  PRIMARY KEY,
    matchpoint  INT     NOT NULL REFERENCES config.circ_matrix_matchpoint (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    limit_set   INT     NOT NULL REFERENCES config.circ_limit_set (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    fallthrough BOOL    NOT NULL DEFAULT FALSE, -- If true fallthrough will grab this rule as it goes along
    active      BOOL    NOT NULL DEFAULT TRUE,
    CONSTRAINT circ_limit_set_once_per_matchpoint UNIQUE (matchpoint, limit_set)
);

-- Linkage between limit sets and circ mods
CREATE TABLE config.circ_limit_set_circ_mod_map (
    id          SERIAL  PRIMARY KEY,
    limit_set   INT     NOT NULL REFERENCES config.circ_limit_set (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    circ_mod    TEXT    NOT NULL REFERENCES config.circ_modifier (code) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT cm_once_per_set UNIQUE (limit_set, circ_mod)
);

-- Linkage between limit sets and limit groups
CREATE TABLE config.circ_limit_set_group_map (
    id          SERIAL  PRIMARY KEY,
    limit_set    INT     NOT NULL REFERENCES config.circ_limit_set (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    limit_group INT     NOT NULL REFERENCES config.circ_limit_group (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    check_only  BOOL    NOT NULL DEFAULT FALSE, -- If true, don't accumulate this limit_group for storing with the circulation
    CONSTRAINT clg_once_per_set UNIQUE (limit_set, limit_group)
);


CREATE TYPE config.usr_activity_group AS ENUM ('authen','authz','circ','hold','search');

CREATE TABLE config.usr_activity_type (
    id          SERIAL                      PRIMARY KEY, 
    ewho        TEXT,
    ewhat       TEXT,
    ehow        TEXT,
    label       TEXT                        NOT NULL, -- i18n
    egroup      config.usr_activity_group   NOT NULL,
    enabled     BOOL                        NOT NULL DEFAULT TRUE,
    transient   BOOL                        NOT NULL DEFAULT FALSE,
    CONSTRAINT  one_of_wwh CHECK (COALESCE(ewho,ewhat,ehow) IS NOT NULL)
);
CREATE UNIQUE INDEX unique_wwh ON config.usr_activity_type 
    (COALESCE(ewho,''), COALESCE (ewhat,''), COALESCE(ehow,''));

ALTER TABLE config.metabib_class ADD COLUMN buoyant BOOL DEFAULT FALSE NOT NULL;
UPDATE config.metabib_class SET buoyant = bouyant;
ALTER TABLE config.metabib_class DROP COLUMN bouyant;

ALTER TABLE config.upgrade_log DROP COLUMN IF EXISTS applied_to;

--TODO: Commented out for testing, should be fine during actual run.
INSERT INTO config.upgrade_log (version) VALUES ('2.2.0');

ALTER TABLE config.upgrade_log
    ADD COLUMN applied_to TEXT;

--FROM Function Script	
--USED by Trigger: create_or_update_code_unknown
DROP FUNCTION IF EXISTS config.create_or_update_code_unknown();
CREATE OR REPLACE FUNCTION config.create_or_update_code_unknown() RETURNS trigger AS $$
BEGIN
UPDATE config.coded_value_map
SET code = 'x' WHERE code = ' ' AND ctype = 'audience';
RETURN NULL;
END;
$$
LANGUAGE plpgsql VOLATILE
COST 100;

UPDATE config.coded_value_map
SET code = code WHERE 1=1;

--TRIGGER for function created above
DROP TRIGGER IF EXISTS create_or_update_code_unknown ON config.coded_value_map;
CREATE TRIGGER create_or_update_code_unknown
  AFTER INSERT OR UPDATE
  ON config.coded_value_map
  FOR EACH ROW
  EXECUTE PROCEDURE config.create_or_update_code_unknown();
