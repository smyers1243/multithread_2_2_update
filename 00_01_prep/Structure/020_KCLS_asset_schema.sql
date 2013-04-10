-- Asset Schema Inits

--TODO: check asset.stat_cat_sip_fields.  Table created in 010_KCLS_asset_schema.sql

--ADD TRIGGER to ASSET.COPY which DEPENDS on asset.acp_created
CREATE TRIGGER acp_created_trig
    BEFORE INSERT ON asset.copy
    FOR EACH ROW EXECUTE PROCEDURE asset.acp_created();

	--ADD TRIGGER to SERIAL.UNIT which DEPENDS on asset.acp_created
CREATE TRIGGER sunit_created_trig
    BEFORE INSERT ON serial.unit
    FOR EACH ROW EXECUTE PROCEDURE asset.acp_created();