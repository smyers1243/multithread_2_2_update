-- Asset Schema, Pre Init

DROP TABLE IF EXISTS asset.stat_cat_sip_fields CASCADE;
CREATE TABLE asset.stat_cat_sip_fields (
    field   CHAR(2) PRIMARY KEY,
    name    TEXT    NOT NULL,
    one_only BOOL    NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE asset.stat_cat_sip_fields IS $$
Asset Statistical Category SIP Fields

Contains the list of valid SIP Field identifiers for
Statistical Categories.
$$;