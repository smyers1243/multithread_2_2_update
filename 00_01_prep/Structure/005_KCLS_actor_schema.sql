-- Actor Schema Inits

DROP TABLE IF EXISTS actor.stat_cat_sip_fields CASCADE;
CREATE TABLE actor.stat_cat_sip_fields (
    field     CHAR(2) PRIMARY KEY,
    name      TEXT    NOT NULL,
    one_only  BOOL    NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE actor.stat_cat_sip_fields IS $$
Actor Statistical Category SIP Fields

Contains the list of valid SIP Field identifiers for
Statistical Categories.
$$;

ALTER TABLE actor.stat_cat
    ADD COLUMN sip_field   CHAR(2) REFERENCES actor.stat_cat_sip_fields(field) ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED,
    ADD COLUMN sip_format  TEXT;

ALTER TABLE actor.usr
	ADD COLUMN last_update_time TIMESTAMPTZ;

ALTER TABLE actor.org_unit_setting ADD CONSTRAINT aous_must_be_json CHECK ( is_json(value) );

--CHECK to ensure that ous_change_log() exists, currently running in 020
--CREATE TRIGGER log_ous_change
--    BEFORE INSERT OR UPDATE ON actor.org_unit_setting
--    FOR EACH ROW EXECUTE PROCEDURE ous_change_log();
	
CREATE TABLE actor.address_alert (
    id              SERIAL  PRIMARY KEY,
    owner           INT     NOT NULL REFERENCES actor.org_unit (id) DEFERRABLE INITIALLY DEFERRED,
    active          BOOL    NOT NULL DEFAULT TRUE,
    match_all       BOOL    NOT NULL DEFAULT TRUE,
    alert_message   TEXT    NOT NULL,
    street1         TEXT,
    street2         TEXT,
    city            TEXT,
    county          TEXT,
    state           TEXT,
    country         TEXT,
    post_code       TEXT,
    mailing_address BOOL    NOT NULL DEFAULT FALSE,
    billing_address BOOL    NOT NULL DEFAULT FALSE
);

ALTER TABLE actor.stat_cat
    ADD COLUMN checkout_archive BOOL NOT NULL DEFAULT FALSE;


CREATE TABLE actor.toolbar (
    id          BIGSERIAL   PRIMARY KEY,
    ws          INT         REFERENCES actor.workstation (id) ON DELETE CASCADE,
    org         INT         REFERENCES actor.org_unit (id) ON DELETE CASCADE,
    usr         INT         REFERENCES actor.usr (id) ON DELETE CASCADE,
    label       TEXT        NOT NULL,
    layout      TEXT        NOT NULL,
    CONSTRAINT only_one_type CHECK (
        (ws IS NOT NULL AND COALESCE(org,usr) IS NULL) OR
        (org IS NOT NULL AND COALESCE(ws,usr) IS NULL) OR
        (usr IS NOT NULL AND COALESCE(org,ws) IS NULL)
    ),
    CONSTRAINT layout_must_be_json CHECK ( is_json(layout) )
);
CREATE UNIQUE INDEX label_once_per_ws ON actor.toolbar (ws, label) WHERE ws IS NOT NULL;
CREATE UNIQUE INDEX label_once_per_org ON actor.toolbar (org, label) WHERE org IS NOT NULL;
CREATE UNIQUE INDEX label_once_per_usr ON actor.toolbar (usr, label) WHERE usr IS NOT NULL;

INSERT INTO actor.toolbar(org,label,layout) VALUES
    ( 1, 'circ', '["circ_checkout","circ_checkin","toolbarseparator.1","search_opac","copy_status","toolbarseparator.2","patron_search","patron_register","toolbarspacer.3","hotkeys_toggle"]' ),
    ( 1, 'cat', '["circ_checkin","toolbarseparator.1","search_opac","copy_status","toolbarseparator.2","create_marc","authority_manage","retrieve_last_record","toolbarspacer.3","hotkeys_toggle"]' );

CREATE TABLE actor.stat_cat_entry_default (
    id              SERIAL  PRIMARY KEY,
    stat_cat_entry  INT     NOT NULL REFERENCES actor.stat_cat_entry (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    stat_cat        INT     NOT NULL REFERENCES actor.stat_cat (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    owner           INT     NOT NULL REFERENCES actor.org_unit (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT sced_once_per_owner UNIQUE (stat_cat,owner)
);

COMMENT ON TABLE actor.stat_cat_entry_default IS $$
User Statistical Category Default Entry

A library may choose one of the stat_cat entries to be the
default entry.
$$;

-- Patron stat cat required column
ALTER TABLE actor.stat_cat
    ADD COLUMN required BOOL NOT NULL DEFAULT FALSE;

-- Patron stat cat allow_freetext column
ALTER TABLE actor.stat_cat
    ADD COLUMN allow_freetext BOOL NOT NULL DEFAULT TRUE;


CREATE TYPE actor.org_unit_custom_tree_purpose AS ENUM ('opac');

CREATE TABLE actor.org_unit_custom_tree (
    id              SERIAL  PRIMARY KEY,
    active          BOOLEAN DEFAULT FALSE,
    purpose         actor.org_unit_custom_tree_purpose NOT NULL DEFAULT 'opac' UNIQUE
);

CREATE TABLE actor.org_unit_custom_tree_node (
    id              SERIAL  PRIMARY KEY,
    tree            INTEGER REFERENCES actor.org_unit_custom_tree (id) DEFERRABLE INITIALLY DEFERRED,
	org_unit        INTEGER NOT NULL REFERENCES actor.org_unit (id) DEFERRABLE INITIALLY DEFERRED,
	parent_node     INTEGER REFERENCES actor.org_unit_custom_tree_node (id) DEFERRABLE INITIALLY DEFERRED,
    sibling_order   INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT aouctn_once_per_org UNIQUE (tree, org_unit)
);

