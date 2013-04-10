-- Vandelay Schema Inits

-- TODO:  match_set is missing
CREATE TABLE vandelay.match_set_quality (
    id          SERIAL  PRIMARY KEY,
    match_set   INT     NOT NULL REFERENCES vandelay.match_set (id) ON DELETE CASCADE,
    svf         TEXT    REFERENCES config.record_attr_definition,
    tag         TEXT,
    subfield    TEXT,
    value       TEXT    NOT NULL,
    quality     INT     NOT NULL DEFAULT 1, -- higher is better
    CONSTRAINT vmsq_need_a_subfield_with_a_tag CHECK ((tag IS NOT NULL AND subfield IS NOT NULL) OR tag IS NULL),
    CONSTRAINT vmsq_need_a_tag_or_a_ff CHECK ((tag IS NOT NULL AND svf IS NULL) OR (tag IS NULL AND svf IS NOT NULL))
);
CREATE UNIQUE INDEX vmsq_def_once_per_set ON vandelay.match_set_quality (match_set, COALESCE(tag,''), COALESCE(subfield,''), COALESCE(svf,''), value);

DROP FUNCTION IF EXISTS vandelay.measure_record_quality ( xml TEXT, match_set_id INT );
CREATE OR REPLACE FUNCTION vandelay.measure_record_quality ( xml TEXT, match_set_id INT ) RETURNS INT AS $_$
DECLARE
    out_q   INT := 0;
    rvalue  TEXT;
    test    vandelay.match_set_quality%ROWTYPE;
BEGIN

    FOR test IN SELECT * FROM vandelay.match_set_quality WHERE match_set = match_set_id LOOP
        IF test.tag IS NOT NULL THEN
            FOR rvalue IN SELECT value FROM vandelay.flatten_marc( xml ) WHERE tag = test.tag AND subfield = test.subfield LOOP
                IF test.value = rvalue THEN
                    out_q := out_q + test.quality;
                END IF;
            END LOOP;
        ELSE
            IF test.value = vandelay.extract_rec_attrs(xml, ARRAY[test.svf]) -> test.svf THEN
                out_q := out_q + test.quality;
            END IF;
        END IF;
    END LOOP;

    RETURN out_q;
END;
$_$ LANGUAGE PLPGSQL;

-- ALTER TABLEs...
ALTER TABLE vandelay.queue ADD COLUMN match_set INT REFERENCES vandelay.match_set (id) ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE vandelay.queued_record ADD COLUMN quality INT NOT NULL DEFAULT 0;
ALTER TABLE vandelay.bib_attr_definition DROP COLUMN ident;

CREATE TABLE vandelay.import_error (
    code        TEXT    PRIMARY KEY,
    description TEXT    NOT NULL -- i18n
);

ALTER TABLE vandelay.queued_bib_record
    ADD COLUMN import_error TEXT REFERENCES vandelay.import_error (code) ON DELETE SET NULL ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED,
    ADD COLUMN error_detail TEXT;

ALTER TABLE vandelay.bib_match
    DROP COLUMN field_type,
    DROP COLUMN matched_attr,
    ADD COLUMN quality INT NOT NULL DEFAULT 1,
    ADD COLUMN match_score INT NOT NULL DEFAULT 0;

ALTER TABLE vandelay.import_item
    ADD COLUMN import_error TEXT REFERENCES vandelay.import_error (code) ON DELETE SET NULL ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED,
    ADD COLUMN error_detail TEXT,
    ADD COLUMN imported_as BIGINT REFERENCES asset.copy (id) DEFERRABLE INITIALLY DEFERRED,
    ADD COLUMN import_time TIMESTAMP WITH TIME ZONE;

ALTER TABLE vandelay.merge_profile ADD COLUMN lwm_ratio NUMERIC;

ALTER TABLE vandelay.authority_attr_definition DROP COLUMN ident;
ALTER TABLE vandelay.queued_authority_record
    ADD COLUMN import_error TEXT REFERENCES vandelay.import_error (code) ON DELETE SET NULL ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED,
    ADD COLUMN error_detail TEXT;

ALTER TABLE vandelay.authority_match DROP COLUMN matched_attr;
ALTER TABLE vandelay.authority_match ADD COLUMN quality INTEGER NOT NULL DEFAULT 0;

DROP FUNCTION IF EXISTS vandelay.ingest_items ( import_id BIGINT, attr_def_id BIGINT );
CREATE OR REPLACE FUNCTION vandelay.ingest_items ( import_id BIGINT, attr_def_id BIGINT ) RETURNS SETOF vandelay.import_item AS $$
DECLARE

    owning_lib      TEXT;
    circ_lib        TEXT;
    call_number     TEXT;
    copy_number     TEXT;
    status          TEXT;
    location        TEXT;
    circulate       TEXT;
    deposit         TEXT;
    deposit_amount  TEXT;
    ref             TEXT;
    holdable        TEXT;
    price           TEXT;
    barcode         TEXT;
    circ_modifier   TEXT;
    circ_as_type    TEXT;
    alert_message   TEXT;
    opac_visible    TEXT;
    pub_note        TEXT;
    priv_note       TEXT;

    attr_def        RECORD;
    tmp_attr_set    RECORD;
    attr_set        vandelay.import_item%ROWTYPE;

    xpath           TEXT;
    tmp_str         TEXT;

BEGIN

    SELECT * INTO attr_def FROM vandelay.import_item_attr_definition WHERE id = attr_def_id;

    IF FOUND THEN

        attr_set.definition := attr_def.id;

        -- Build the combined XPath

        owning_lib :=
            CASE
                WHEN attr_def.owning_lib IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.owning_lib ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.owning_lib || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.owning_lib
            END;

        circ_lib :=
            CASE
                WHEN attr_def.circ_lib IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.circ_lib ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.circ_lib || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.circ_lib
            END;

        call_number :=
            CASE
                WHEN attr_def.call_number IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.call_number ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.call_number || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.call_number
            END;

        copy_number :=
            CASE
                WHEN attr_def.copy_number IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.copy_number ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.copy_number || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.copy_number
            END;

        status :=
            CASE
                WHEN attr_def.status IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.status ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.status || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.status
            END;

        location :=
            CASE
                WHEN attr_def.location IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.location ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.location || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.location
            END;

        circulate :=
            CASE
                WHEN attr_def.circulate IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.circulate ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.circulate || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.circulate
            END;

        deposit :=
            CASE
                WHEN attr_def.deposit IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.deposit ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.deposit || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.deposit
            END;

        deposit_amount :=
            CASE
                WHEN attr_def.deposit_amount IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.deposit_amount ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.deposit_amount || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.deposit_amount
            END;

        ref :=
            CASE
                WHEN attr_def.ref IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.ref ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.ref || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.ref
            END;

        holdable :=
            CASE
                WHEN attr_def.holdable IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.holdable ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.holdable || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.holdable
            END;

        price :=
            CASE
                WHEN attr_def.price IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.price ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.price || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.price
            END;

        barcode :=
            CASE
                WHEN attr_def.barcode IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.barcode ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.barcode || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.barcode
            END;

        circ_modifier :=
            CASE
                WHEN attr_def.circ_modifier IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.circ_modifier ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.circ_modifier || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.circ_modifier
            END;

        circ_as_type :=
            CASE
                WHEN attr_def.circ_as_type IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.circ_as_type ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.circ_as_type || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.circ_as_type
            END;

        alert_message :=
            CASE
                WHEN attr_def.alert_message IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.alert_message ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.alert_message || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.alert_message
            END;

        opac_visible :=
            CASE
                WHEN attr_def.opac_visible IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.opac_visible ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.opac_visible || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.opac_visible
            END;

        pub_note :=
            CASE
                WHEN attr_def.pub_note IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.pub_note ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.pub_note || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.pub_note
            END;
        priv_note :=
            CASE
                WHEN attr_def.priv_note IS NULL THEN 'null()'
                WHEN LENGTH( attr_def.priv_note ) = 1 THEN '//*[@tag="' || attr_def.tag || '"]/*[@code="' || attr_def.priv_note || '"]'
                ELSE '//*[@tag="' || attr_def.tag || '"]/*' || attr_def.priv_note
            END;


        xpath :=
            owning_lib      || '|' ||
            circ_lib        || '|' ||
            call_number     || '|' ||
            copy_number     || '|' ||
            status          || '|' ||
            location        || '|' ||
            circulate       || '|' ||
            deposit         || '|' ||
            deposit_amount  || '|' ||
            ref             || '|' ||
            holdable        || '|' ||
            price           || '|' ||
            barcode         || '|' ||
            circ_modifier   || '|' ||
            circ_as_type    || '|' ||
            alert_message   || '|' ||
            pub_note        || '|' ||
            priv_note       || '|' ||
            opac_visible;

        FOR tmp_attr_set IN
                SELECT  *
                  FROM  oils_xpath_table( 'id', 'marc', 'vandelay.queued_bib_record', xpath, 'id = ' || import_id )
                            AS t( id INT, ol TEXT, clib TEXT, cn TEXT, cnum TEXT, cs TEXT, cl TEXT, circ TEXT,
                                  dep TEXT, dep_amount TEXT, r TEXT, hold TEXT, pr TEXT, bc TEXT, circ_mod TEXT,
                                  circ_as TEXT, amessage TEXT, note TEXT, pnote TEXT, opac_vis TEXT )
        LOOP

            attr_set.import_error := NULL;
            attr_set.error_detail := NULL;
            attr_set.deposit_amount := NULL;
            attr_set.copy_number := NULL;
            attr_set.price := NULL;

            IF tmp_attr_set.pr != '' THEN
                tmp_str = REGEXP_REPLACE(tmp_attr_set.pr, E'[^0-9\\.]', '', 'g');
                IF tmp_str = '' THEN 
                    attr_set.import_error := 'import.item.invalid.price';
                    attr_set.error_detail := tmp_attr_set.pr; -- original value
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
                attr_set.price := tmp_str::NUMERIC(8,2); 
            END IF;

            IF tmp_attr_set.dep_amount != '' THEN
                tmp_str = REGEXP_REPLACE(tmp_attr_set.dep_amount, E'[^0-9\\.]', '', 'g');
                IF tmp_str = '' THEN 
                    attr_set.import_error := 'import.item.invalid.deposit_amount';
                    attr_set.error_detail := tmp_attr_set.dep_amount; 
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
                attr_set.deposit_amount := tmp_str::NUMERIC(8,2); 
            END IF;

            IF tmp_attr_set.cnum != '' THEN
                tmp_str = REGEXP_REPLACE(tmp_attr_set.cnum, E'[^0-9]', '', 'g');
                IF tmp_str = '' THEN 
                    attr_set.import_error := 'import.item.invalid.copy_number';
                    attr_set.error_detail := tmp_attr_set.cnum; 
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
                attr_set.copy_number := tmp_str::INT; 
            END IF;

            IF tmp_attr_set.ol != '' THEN
                SELECT id INTO attr_set.owning_lib FROM actor.org_unit WHERE shortname = UPPER(tmp_attr_set.ol); -- INT
                IF NOT FOUND THEN
                    attr_set.import_error := 'import.item.invalid.owning_lib';
                    attr_set.error_detail := tmp_attr_set.ol;
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
            END IF;

            IF tmp_attr_set.clib != '' THEN
                SELECT id INTO attr_set.circ_lib FROM actor.org_unit WHERE shortname = UPPER(tmp_attr_set.clib); -- INT
                IF NOT FOUND THEN
                    attr_set.import_error := 'import.item.invalid.circ_lib';
                    attr_set.error_detail := tmp_attr_set.clib;
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
            END IF;

            IF tmp_attr_set.cs != '' THEN
                SELECT id INTO attr_set.status FROM config.copy_status WHERE LOWER(name) = LOWER(tmp_attr_set.cs); -- INT
                IF NOT FOUND THEN
                    attr_set.import_error := 'import.item.invalid.status';
                    attr_set.error_detail := tmp_attr_set.cs;
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
            END IF;

            IF tmp_attr_set.circ_mod != '' THEN
                SELECT code INTO attr_set.circ_modifier FROM config.circ_modifier WHERE code = tmp_attr_set.circ_mod;
                IF NOT FOUND THEN
                    attr_set.import_error := 'import.item.invalid.circ_modifier';
                    attr_set.error_detail := tmp_attr_set.circ_mod;
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
            END IF;

            IF tmp_attr_set.circ_as != '' THEN
                SELECT code INTO attr_set.circ_as_type FROM config.coded_value_map WHERE ctype = 'item_type' AND code = tmp_attr_set.circ_as;
                IF NOT FOUND THEN
                    attr_set.import_error := 'import.item.invalid.circ_as_type';
                    attr_set.error_detail := tmp_attr_set.circ_as;
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
            END IF;

            IF tmp_attr_set.cl != '' THEN

                -- search up the org unit tree for a matching copy location
                WITH RECURSIVE anscestor_depth AS (
                    SELECT  ou.id,
                        out.depth AS depth,
                        ou.parent_ou
                    FROM  actor.org_unit ou
                        JOIN actor.org_unit_type out ON (out.id = ou.ou_type)
                    WHERE ou.id = COALESCE(attr_set.owning_lib, attr_set.circ_lib)
                        UNION ALL
                    SELECT  ou.id,
                        out.depth,
                        ou.parent_ou
                    FROM  actor.org_unit ou
                        JOIN actor.org_unit_type out ON (out.id = ou.ou_type)
                        JOIN anscestor_depth ot ON (ot.parent_ou = ou.id)
                ) SELECT  cpl.id INTO attr_set.location
                    FROM  anscestor_depth a
                        JOIN asset.copy_location cpl ON (cpl.owning_lib = a.id)
                    WHERE LOWER(cpl.name) = LOWER(tmp_attr_set.cl)
                    ORDER BY a.depth DESC
                    LIMIT 1; 

                IF NOT FOUND THEN
                    attr_set.import_error := 'import.item.invalid.location';
                    attr_set.error_detail := tmp_attr_set.cs;
                    RETURN NEXT attr_set; CONTINUE; 
                END IF;
            END IF;

            attr_set.circulate      :=
                LOWER( SUBSTRING( tmp_attr_set.circ, 1, 1)) IN ('t','y','1')
                OR LOWER(tmp_attr_set.circ) = 'circulating'; -- BOOL

            attr_set.deposit        :=
                LOWER( SUBSTRING( tmp_attr_set.dep, 1, 1 ) ) IN ('t','y','1')
                OR LOWER(tmp_attr_set.dep) = 'deposit'; -- BOOL

            attr_set.holdable       :=
                LOWER( SUBSTRING( tmp_attr_set.hold, 1, 1 ) ) IN ('t','y','1')
                OR LOWER(tmp_attr_set.hold) = 'holdable'; -- BOOL

            attr_set.opac_visible   :=
                LOWER( SUBSTRING( tmp_attr_set.opac_vis, 1, 1 ) ) IN ('t','y','1')
                OR LOWER(tmp_attr_set.opac_vis) = 'visible'; -- BOOL

            attr_set.ref            :=
                LOWER( SUBSTRING( tmp_attr_set.r, 1, 1 ) ) IN ('t','y','1')
                OR LOWER(tmp_attr_set.r) = 'reference'; -- BOOL

            attr_set.call_number    := tmp_attr_set.cn; -- TEXT
            attr_set.barcode        := tmp_attr_set.bc; -- TEXT,
            attr_set.alert_message  := tmp_attr_set.amessage; -- TEXT,
            attr_set.pub_note       := tmp_attr_set.note; -- TEXT,
            attr_set.priv_note      := tmp_attr_set.pnote; -- TEXT,
            attr_set.alert_message  := tmp_attr_set.amessage; -- TEXT,

            RETURN NEXT attr_set;

        END LOOP;

    END IF;

    RETURN;

END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS vandelay.auto_overlay_bib_queue_with_best ( import_id BIGINT, merge_profile_id INT );
CREATE OR REPLACE FUNCTION vandelay.auto_overlay_bib_queue_with_best ( import_id BIGINT, merge_profile_id INT ) RETURNS SETOF BIGINT AS $$
    SELECT vandelay.auto_overlay_bib_queue_with_best( $1, $2, p.lwm_ratio ) FROM vandelay.merge_profile p WHERE id = $2;
$$ LANGUAGE SQL;

-- Replace the constraints with more flexible ENUM's
ALTER TABLE vandelay.queue DROP CONSTRAINT queue_queue_type_check;
ALTER TABLE vandelay.bib_queue DROP CONSTRAINT bib_queue_queue_type_check;
ALTER TABLE vandelay.authority_queue DROP CONSTRAINT authority_queue_queue_type_check;

CREATE TYPE vandelay.bib_queue_queue_type AS ENUM ('bib', 'acq');
CREATE TYPE vandelay.authority_queue_queue_type AS ENUM ('authority');

-- dropped column is also implemented by the child tables
ALTER TABLE vandelay.queue DROP COLUMN queue_type; 

-- modify the child tables to use the ENUMs
ALTER TABLE vandelay.bib_queue 
    ALTER COLUMN queue_type DROP DEFAULT,
    ALTER COLUMN queue_type TYPE vandelay.bib_queue_queue_type 
        USING (queue_type::vandelay.bib_queue_queue_type),
    ALTER COLUMN queue_type SET DEFAULT 'bib';

ALTER TABLE vandelay.authority_queue 
    ALTER COLUMN queue_type DROP DEFAULT,
    ALTER COLUMN queue_type TYPE vandelay.authority_queue_queue_type 
        USING (queue_type::vandelay.authority_queue_queue_type),
    ALTER COLUMN queue_type SET DEFAULT 'authority';
	
INSERT INTO vandelay.merge_profile (owner, name, replace_spec) 
    VALUES (1, 'Match-Only Merge', '901c');

INSERT INTO vandelay.merge_profile (owner, name, preserve_spec) 
    VALUES (1, 'Full Overlay', '901c');
	
DROP TRIGGER IF EXISTS zz_match_bibs_trigger ON vandelay.queued_bib_record;
CREATE TRIGGER zz_match_bibs_trigger
    BEFORE INSERT OR UPDATE ON vandelay.queued_bib_record
    FOR EACH ROW EXECUTE PROCEDURE vandelay.match_bib_record();
