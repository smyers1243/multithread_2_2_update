-- Unapi Schema Inits

-- DROP SCHEMA IF EXISTS unapi CASCADE;
-- CREATE SCHEMA unapi;

DROP TABLE unapi.bre_output_layout;
CREATE TABLE unapi.bre_output_layout (
    name                TEXT    PRIMARY KEY,
    transform           TEXT    REFERENCES config.xml_transform (name) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED,
    mime_type           TEXT    NOT NULL,
    feed_top            TEXT    NOT NULL,
    holdings_element    TEXT,
    title_element       TEXT,
    description_element TEXT,
    creator_element     TEXT,
    update_ts_element   TEXT
);

INSERT INTO unapi.bre_output_layout
    (name,           transform, mime_type,              holdings_element, feed_top,         title_element, description_element, creator_element, update_ts_element)
        VALUES
    ('holdings_xml', NULL,      'application/xml',      NULL,             'hxml',           NULL,          NULL,                NULL,            NULL),
    ('marcxml',      'marcxml', 'application/marc+xml', 'record',         'collection',     NULL,          NULL,                NULL,            NULL),
    ('mods32',       'mods32',  'application/mods+xml', 'mods',           'modsCollection', NULL,          NULL,                NULL,            NULL)
;

-- Dummy functions, so we can create the real ones out of order
CREATE OR REPLACE FUNCTION unapi.aou    ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.acnp   ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.acns   ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.acn    ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.ssub   ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.sdist  ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.sstr   ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.sitem  ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.sunit  ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.sisum  ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.sbsum  ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.sssum  ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.siss   ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.auri   ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.acp    ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.acpn   ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.acl    ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.ccs    ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.ascecm ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.bmp    ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.mra    ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT, depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
CREATE OR REPLACE FUNCTION unapi.circ   ( obj_id BIGINT, format TEXT, ename TEXT, includes TEXT[], org TEXT DEFAULT '-', depth INT DEFAULT NULL, slimit HSTORE DEFAULT NULL, soffset HSTORE DEFAULT NULL, include_xmlns BOOL DEFAULT TRUE ) RETURNS XML AS $F$ SELECT NULL::XML $F$ LANGUAGE SQL STABLE;
