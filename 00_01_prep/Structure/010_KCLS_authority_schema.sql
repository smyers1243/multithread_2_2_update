-- Authority Schema Inits
CREATE TABLE authority.control_set (
    id          SERIAL  PRIMARY KEY,
    name        TEXT    NOT NULL UNIQUE, -- i18n
    description TEXT                     -- i18n
);

CREATE TABLE authority.control_set_authority_field (
    id          SERIAL  PRIMARY KEY,
    main_entry  INT     REFERENCES authority.control_set_authority_field (id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    control_set INT     NOT NULL REFERENCES authority.control_set (id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    tag         CHAR(3) NOT NULL,
    nfi CHAR(1),
    sf_list     TEXT    NOT NULL,
    name        TEXT    NOT NULL, -- i18n
    description TEXT              -- i18n
);

CREATE TABLE authority.control_set_bib_field (
    id              SERIAL  PRIMARY KEY,
    authority_field INT     NOT NULL REFERENCES authority.control_set_authority_field (id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    tag             CHAR(3) NOT NULL
);

CREATE TABLE authority.thesaurus (
    code        TEXT    PRIMARY KEY,     -- MARC21 thesaurus code
    control_set INT     REFERENCES authority.control_set (id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    name        TEXT    NOT NULL UNIQUE, -- i18n
    description TEXT                     -- i18n
);

CREATE TABLE authority.browse_axis (
    code        TEXT    PRIMARY KEY,
    name        TEXT    UNIQUE NOT NULL, -- i18n
    sorter      TEXT    REFERENCES config.record_attr_definition (name) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    description TEXT
);

CREATE TABLE authority.browse_axis_authority_field_map (
    id          SERIAL  PRIMARY KEY,
    axis        TEXT    NOT NULL REFERENCES authority.browse_axis (code) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    field       INT     NOT NULL REFERENCES authority.control_set_authority_field (id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

ALTER TABLE authority.record_entry ADD COLUMN control_set INT REFERENCES authority.control_set (id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE authority.rec_descriptor DROP COLUMN char_encoding, ADD COLUMN encoding_level TEXT, ADD COLUMN thesaurus TEXT;

CREATE INDEX authority_full_rec_value_index ON authority.full_rec (value);
CREATE OR REPLACE RULE protect_authority_rec_delete AS ON DELETE TO authority.record_entry DO INSTEAD (UPDATE authority.record_entry SET deleted = TRUE WHERE OLD.id = authority.record_entry.id; DELETE FROM authority.full_rec WHERE record = OLD.id);
 
 DROP TRIGGER authority_full_rec_fti_trigger ON authority.full_rec;
CREATE TRIGGER authority_full_rec_fti_trigger
    BEFORE UPDATE OR INSERT ON authority.full_rec
    FOR EACH ROW EXECUTE PROCEDURE oils_tsearch2('keyword');
	
CREATE OR REPLACE VIEW authority.tracing_links AS
    SELECT  main.record AS record,
            main.id AS main_id,
            main.tag AS main_tag,
            oils_xpath_string('//*[@tag="'||main.tag||'"]/*[local-name()="subfield"]', are.marc) AS main_value,
            substr(link.value,1,1) AS relationship,
            substr(link.value,2,1) AS use_restriction,
            substr(link.value,3,1) AS deprecation,
            substr(link.value,4,1) AS display_restriction,
            link.id AS link_id,
            link.tag AS link_tag,
            oils_xpath_string('//*[@tag="'||link.tag||'"]/*[local-name()="subfield"]', are.marc) AS link_value,
            authority.normalize_heading(are.marc) AS normalized_main_value
      FROM  authority.full_rec main
            JOIN authority.record_entry are ON (main.record = are.id)
            JOIN authority.control_set_authority_field main_entry
                ON (main_entry.tag = main.tag
                    AND main_entry.main_entry IS NULL
                    AND main.subfield = 'a' )
            JOIN authority.control_set_authority_field sub_entry
                ON (main_entry.id = sub_entry.main_entry)
            JOIN authority.full_rec link
                ON (link.record = main.record
                    AND link.tag = sub_entry.tag
                    AND link.subfield = 'w' );
 
--ALTER TABLE auditor.actor_usr_history
--	ADD COLUMN last_update_time TIMESTAMPTZ;

CREATE TABLE authority.simple_heading (
    id              BIGSERIAL   PRIMARY KEY,
    record          BIGINT      NOT NULL REFERENCES authority.record_entry (id),
    atag            INT         NOT NULL REFERENCES authority.control_set_authority_field (id),
    value           TEXT        NOT NULL,
    sort_value      TEXT        NOT NULL,
    index_vector    tsvector    NOT NULL
);

CREATE INDEX authority_simple_heading_index_vector_idx ON authority.simple_heading USING GIST (index_vector);
CREATE INDEX authority_simple_heading_value_idx ON authority.simple_heading (value);
CREATE INDEX authority_simple_heading_sort_value_idx ON authority.simple_heading (sort_value);

--FROM Function Script /start
DROP FUNCTION IF EXISTS authority.normalize_heading( marcxml TEXT, no_thesaurus BOOL );
CREATE OR REPLACE FUNCTION authority.normalize_heading( marcxml TEXT, no_thesaurus BOOL ) RETURNS TEXT AS $func$
DECLARE
    acsaf           authority.control_set_authority_field%ROWTYPE;
    tag_used        TEXT;
    sf              TEXT;
    thes_code       TEXT;
    cset            INT;
    heading_text    TEXT;
    tmp_text        TEXT;
BEGIN
    thes_code := vandelay.marc21_extract_fixed_field(marcxml,'Subj');
    IF thes_code IS NULL THEN
        thes_code := '|';
    END IF;

    SELECT control_set INTO cset FROM authority.thesaurus WHERE code = thes_code;
    IF NOT FOUND THEN
        cset = 1;
    END IF;

    heading_text := '';
    FOR acsaf IN SELECT * FROM authority.control_set_authority_field WHERE control_set = cset AND main_entry IS NULL LOOP
        tag_used := acsaf.tag;
        FOR sf IN SELECT * FROM regexp_split_to_table(acsaf.sf_list,'') LOOP
            tmp_text := oils_xpath_string('//*[@tag="'||tag_used||'"]/*[@code="'||sf||'"]', marcxml);
            IF tmp_text IS NOT NULL AND tmp_text <> '' THEN
                heading_text := heading_text || E'\u2021' || sf || ' ' || tmp_text;
            END IF;
        END LOOP;
        EXIT WHEN heading_text <> '';
    END LOOP;
 
    IF thes_code = 'z' THEN
        thes_code := oils_xpath_string('//*[@tag="040"]/*[@code="f"][1]', marcxml);
    END IF;

    IF heading_text <> '' THEN
        IF no_thesaurus IS TRUE THEN
            heading_text := tag_used || ' ' || public.naco_normalize(heading_text);
        ELSE
            heading_text := tag_used || '_' || thes_code || ' ' || public.naco_normalize(heading_text);
        END IF;
    ELSE
        heading_text := 'NOHEADING_' || thes_code || ' ' || MD5(marcxml);
    END IF;

    RETURN heading_text;
END;
$func$ LANGUAGE PLPGSQL IMMUTABLE;

DROP FUNCTION IF EXISTS authority.simple_normalize_heading( marcxml TEXT );
CREATE OR REPLACE FUNCTION authority.simple_normalize_heading( marcxml TEXT ) RETURNS TEXT AS $func$
    SELECT authority.normalize_heading($1, TRUE);
$func$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION authority.normalize_heading( marcxml TEXT ) RETURNS TEXT AS $func$
    SELECT authority.normalize_heading($1, FALSE);
$func$ LANGUAGE SQL IMMUTABLE;

DROP FUNCTION IF EXISTS authority.generate_overlay_template (source_xml TEXT);
CREATE OR REPLACE FUNCTION authority.generate_overlay_template (source_xml TEXT) RETURNS TEXT AS $f$
DECLARE
    cset                INT;
    main_entry          authority.control_set_authority_field%ROWTYPE;
    bib_field           authority.control_set_bib_field%ROWTYPE;
    auth_id             INT DEFAULT oils_xpath_string('//*[@tag="901"]/*[local-name()="subfield" and @code="c"]', source_xml)::INT;
    replace_data        XML[] DEFAULT '{}'::XML[];
    replace_rules       TEXT[] DEFAULT '{}'::TEXT[];
    auth_field          XML[];
BEGIN
    IF auth_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Default to the LoC controll set
    SELECT COALESCE(control_set,1) INTO cset FROM authority.record_entry WHERE id = auth_id;

    FOR main_entry IN SELECT * FROM authority.control_set_authority_field WHERE control_set = cset LOOP
        auth_field := XPATH('//*[@tag="'||main_entry.tag||'"][1]',source_xml::XML);
        IF ARRAY_LENGTH(auth_field,1) > 0 THEN
            FOR bib_field IN SELECT * FROM authority.control_set_bib_field WHERE authority_field = main_entry.id LOOP
                replace_data := replace_data || XMLELEMENT( name datafield, XMLATTRIBUTES(bib_field.tag AS tag), XPATH('//*[local-name()="subfield"]',auth_field[1])::XML[]);
                replace_rules := replace_rules || ( bib_field.tag || main_entry.sf_list || E'[0~\\)' || auth_id || '$]' );
            END LOOP;
            EXIT;
        END IF;
    END LOOP;
 
    RETURN XMLELEMENT(
        name record,
        XMLATTRIBUTES('http://www.loc.gov/MARC21/slim' AS xmlns),
        XMLELEMENT( name leader, '00881nam a2200193   4500'),
        replace_data,
        XMLELEMENT(
            name datafield,
            XMLATTRIBUTES( '905' AS tag, ' ' AS ind1, ' ' AS ind2),
            XMLELEMENT(
                name subfield,
                XMLATTRIBUTES('r' AS code),
                ARRAY_TO_STRING(replace_rules,',')
            )
        )
    )::TEXT;
END;
$f$ STABLE LANGUAGE PLPGSQL;
 
 DROP FUNCTION IF EXISTS authority.generate_overlay_template ( BIGINT );
CREATE OR REPLACE FUNCTION authority.generate_overlay_template ( BIGINT ) RETURNS TEXT AS $func$
    SELECT authority.generate_overlay_template( marc ) FROM authority.record_entry WHERE id = $1;
$func$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS authority.map_thesaurus_to_control_set ();
CREATE OR REPLACE FUNCTION authority.map_thesaurus_to_control_set () RETURNS TRIGGER AS $func$
BEGIN
    IF NEW.control_set IS NULL THEN
        SELECT  control_set INTO NEW.control_set
          FROM  authority.thesaurus
          WHERE vandelay.marc21_extract_fixed_field(NEW.marc,'Subj') = code;
    END IF;

    RETURN NEW;
END;
$func$ LANGUAGE PLPGSQL;

CREATE TRIGGER map_thesaurus_to_control_set BEFORE INSERT OR UPDATE ON authority.record_entry FOR EACH ROW EXECUTE PROCEDURE authority.map_thesaurus_to_control_set ();

DROP FUNCTION IF EXISTS authority.reingest_authority_rec_descriptor( auth_id BIGINT );
CREATE OR REPLACE FUNCTION authority.reingest_authority_rec_descriptor( auth_id BIGINT ) RETURNS VOID AS $func$
BEGIN
    DELETE FROM authority.rec_descriptor WHERE record = auth_id;
    INSERT INTO authority.rec_descriptor (record, record_status, encoding_level, thesaurus)
        SELECT  auth_id,
                vandelay.marc21_extract_fixed_field(marc,'RecStat'),
                vandelay.marc21_extract_fixed_field(marc,'ELvl'),
                vandelay.marc21_extract_fixed_field(marc,'Subj')
          FROM  authority.record_entry
          WHERE id = auth_id;
     RETURN;
 END;
 $func$ LANGUAGE PLPGSQL;

 DROP FUNCTION IF EXISTS authority.generate_overlay_template (source_xml TEXT);
-- Function to generate an ephemeral overlay template from an authority record
CREATE OR REPLACE FUNCTION authority.generate_overlay_template (source_xml TEXT) RETURNS TEXT AS $f$
DECLARE
    cset                INT;
    main_entry          authority.control_set_authority_field%ROWTYPE;
    bib_field           authority.control_set_bib_field%ROWTYPE;
    auth_id             INT DEFAULT oils_xpath_string('//*[@tag="901"]/*[local-name()="subfield" and @code="c"]', source_xml)::INT;
    replace_data        XML[] DEFAULT '{}'::XML[];
    replace_rules       TEXT[] DEFAULT '{}'::TEXT[];
    auth_field          XML[];
BEGIN
    IF auth_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Default to the LoC controll set
    SELECT control_set INTO cset FROM authority.record_entry WHERE id = auth_id;

    -- if none, make a best guess
    IF cset IS NULL THEN
        SELECT  control_set INTO cset
          FROM  authority.control_set_authority_field
          WHERE tag IN (
                    SELECT  UNNEST(XPATH('//*[starts-with(@tag,"1")]/@tag',marc::XML)::TEXT[])
                      FROM  authority.record_entry
                      WHERE id = auth_id
                )
          LIMIT 1;
    END IF;

    -- if STILL none, no-op change
    IF cset IS NULL THEN
        RETURN XMLELEMENT(
            name record,
            XMLATTRIBUTES('http://www.loc.gov/MARC21/slim' AS xmlns),
            XMLELEMENT( name leader, '00881nam a2200193   4500'),
            XMLELEMENT(
                name datafield,
                XMLATTRIBUTES( '905' AS tag, ' ' AS ind1, ' ' AS ind2),
                XMLELEMENT(
                    name subfield,
                    XMLATTRIBUTES('d' AS code),
                    '901c'
                )
            )
        )::TEXT;
    END IF;

    FOR main_entry IN SELECT * FROM authority.control_set_authority_field WHERE control_set = cset LOOP
        auth_field := XPATH('//*[@tag="'||main_entry.tag||'"][1]',source_xml::XML);
        IF ARRAY_LENGTH(auth_field,1) > 0 THEN
            FOR bib_field IN SELECT * FROM authority.control_set_bib_field WHERE authority_field = main_entry.id LOOP
                replace_data := replace_data || XMLELEMENT( name datafield, XMLATTRIBUTES(bib_field.tag AS tag), XPATH('//*[local-name()="subfield"]',auth_field[1])::XML[]);
                replace_rules := replace_rules || ( bib_field.tag || main_entry.sf_list || E'[0~\\)' || auth_id || '$]' );
            END LOOP;
            EXIT;
        END IF;
    END LOOP;

    RETURN XMLELEMENT(
        name record,
        XMLATTRIBUTES('http://www.loc.gov/MARC21/slim' AS xmlns),
        XMLELEMENT( name leader, '00881nam a2200193   4500'),
        replace_data,
        XMLELEMENT(
            name datafield,
            XMLATTRIBUTES( '905' AS tag, ' ' AS ind1, ' ' AS ind2),
            XMLELEMENT(
                name subfield,
                XMLATTRIBUTES('r' AS code),
                ARRAY_TO_STRING(replace_rules,',')
            )
        )
    )::TEXT;
END;
$f$ STABLE LANGUAGE PLPGSQL;

-- AFTER UPDATE OR INSERT trigger for authority.record_entry
CREATE OR REPLACE FUNCTION authority.indexing_ingest_or_delete () RETURNS TRIGGER AS $func$
BEGIN

    IF NEW.deleted IS TRUE THEN -- If this authority is deleted
        DELETE FROM authority.bib_linking WHERE authority = NEW.id; -- Avoid updating fields in bibs that are no longer visible
        DELETE FROM authority.full_rec WHERE record = NEW.id; -- Avoid validating fields against deleted authority records
        DELETE FROM authority.simple_heading WHERE record = NEW.id;
          -- Should remove matching $0 from controlled fields at the same time?
        RETURN NEW; -- and we're done
    END IF;

    IF TG_OP = 'UPDATE' THEN -- re-ingest?
        PERFORM * FROM config.internal_flag WHERE name = 'ingest.reingest.force_on_same_marc' AND enabled;

        IF NOT FOUND AND OLD.marc = NEW.marc THEN -- don't do anything if the MARC didn't change
            RETURN NEW;
        END IF;

        -- Propagate these updates to any linked bib records
        PERFORM authority.propagate_changes(NEW.id) FROM authority.record_entry WHERE id = NEW.id;

        DELETE FROM authority.simple_heading WHERE record = NEW.id;
    END IF;

    INSERT INTO authority.simple_heading (record,atag,value,sort_value)
        SELECT record, atag, value, sort_value FROM authority.simple_heading_set(NEW.marc);

    -- Flatten and insert the afr data
    PERFORM * FROM config.internal_flag WHERE name = 'ingest.disable_authority_full_rec' AND enabled;
    IF NOT FOUND THEN
        PERFORM authority.reingest_authority_full_rec(NEW.id);
        PERFORM * FROM config.internal_flag WHERE name = 'ingest.disable_authority_rec_descriptor' AND enabled;
        IF NOT FOUND THEN
            PERFORM authority.reingest_authority_rec_descriptor(NEW.id);
        END IF;
    END IF;

    RETURN NEW;
END;
$func$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS authority.normalize_heading( marcxml TEXT, no_thesaurus BOOL );
CREATE OR REPLACE FUNCTION authority.normalize_heading( marcxml TEXT, no_thesaurus BOOL ) RETURNS TEXT AS $func$
DECLARE
    acsaf           authority.control_set_authority_field%ROWTYPE;
    tag_used        TEXT;
    nfi_used        TEXT;
    sf              TEXT;
    thes_code       TEXT;
    cset            INT;
    heading_text    TEXT;
    tmp_text        TEXT;
    first_sf        BOOL;
    auth_id         INT DEFAULT oils_xpath_string('//*[@tag="901"]/*[local-name()="subfield" and @code="c"]', marcxml)::INT;
BEGIN
    SELECT control_set INTO cset FROM authority.record_entry WHERE id = auth_id;

    IF cset IS NULL THEN
        SELECT  control_set INTO cset
          FROM  authority.control_set_authority_field
          WHERE tag IN ( SELECT  UNNEST(XPATH('//*[starts-with(@tag,"1")]/@tag',marcxml::XML)::TEXT[]))
          LIMIT 1;
    END IF;

    thes_code := vandelay.marc21_extract_fixed_field(marcxml,'Subj');
    IF thes_code IS NULL THEN
        thes_code := '|';
    ELSIF thes_code = 'z' THEN
        thes_code := COALESCE( oils_xpath_string('//*[@tag="040"]/*[@code="f"][1]', marcxml), '' );
    END IF;

    heading_text := '';
    FOR acsaf IN SELECT * FROM authority.control_set_authority_field WHERE control_set = cset AND main_entry IS NULL LOOP
        tag_used := acsaf.tag;
        nfi_used := acsaf.nfi;
        first_sf := TRUE;
        FOR sf IN SELECT * FROM regexp_split_to_table(acsaf.sf_list,'') LOOP
            tmp_text := oils_xpath_string('//*[@tag="'||tag_used||'"]/*[@code="'||sf||'"]', marcxml);

            IF first_sf AND tmp_text IS NOT NULL AND nfi_used IS NOT NULL THEN

                tmp_text := SUBSTRING(
                    tmp_text FROM
                    COALESCE(
                        NULLIF(
                            REGEXP_REPLACE(
                                oils_xpath_string('//*[@tag="'||tag_used||'"]/@ind'||nfi_used, marcxml),
                                $$\D+$$,
                                '',
                                'g'
                            ),
                            ''
                        )::INT,
                        0
                    ) + 1
                );

            END IF;

            first_sf := FALSE;

            IF tmp_text IS NOT NULL AND tmp_text <> '' THEN
                heading_text := heading_text || E'\u2021' || sf || ' ' || tmp_text;
            END IF;
        END LOOP;
        EXIT WHEN heading_text <> '';
    END LOOP;

    IF heading_text <> '' THEN
        IF no_thesaurus IS TRUE THEN
            heading_text := tag_used || ' ' || public.naco_normalize(heading_text);
        ELSE
            heading_text := tag_used || '_' || COALESCE(nfi_used,'-') || '_' || thes_code || ' ' || public.naco_normalize(heading_text);
        END IF;
    ELSE
        heading_text := 'NOHEADING_' || thes_code || ' ' || MD5(marcxml);
    END IF;

    RETURN heading_text;
END;
$func$ LANGUAGE PLPGSQL IMMUTABLE;

DROP FUNCTION IF EXISTS authority.simple_normalize_heading( marcxml TEXT );
CREATE OR REPLACE FUNCTION authority.simple_normalize_heading( marcxml TEXT ) RETURNS TEXT AS $func$
    SELECT authority.normalize_heading($1, TRUE);
$func$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION authority.normalize_heading( marcxml TEXT ) RETURNS TEXT AS $func$
    SELECT authority.normalize_heading($1, FALSE);
$func$ LANGUAGE SQL IMMUTABLE;

CREATE TRIGGER authority_simple_heading_fti_trigger
    BEFORE UPDATE OR INSERT ON authority.simple_heading
    FOR EACH ROW EXECUTE PROCEDURE oils_tsearch2('keyword');

	DROP FUNCTION IF EXISTS authority.simple_heading_set( marcxml TEXT );
	CREATE OR REPLACE FUNCTION authority.simple_heading_set( marcxml TEXT ) RETURNS SETOF authority.simple_heading AS $func$
DECLARE
    res             authority.simple_heading%ROWTYPE;
    acsaf           authority.control_set_authority_field%ROWTYPE;
    tag_used        TEXT;
    nfi_used        TEXT;
    sf              TEXT;
    cset            INT;
    heading_text    TEXT;
    sort_text       TEXT;
    tmp_text        TEXT;
    tmp_xml         TEXT;
    first_sf        BOOL;
    auth_id         INT DEFAULT oils_xpath_string('//*[@tag="901"]/*[local-name()="subfield" and @code="c"]', marcxml)::INT;
BEGIN

    res.record := auth_id;

    SELECT  control_set INTO cset
      FROM  authority.control_set_authority_field
      WHERE tag IN ( SELECT UNNEST(XPATH('//*[starts-with(@tag,"1")]/@tag',marcxml::XML)::TEXT[]) )
      LIMIT 1;

    FOR acsaf IN SELECT * FROM authority.control_set_authority_field WHERE control_set = cset LOOP

        res.atag := acsaf.id;
        tag_used := acsaf.tag;
        nfi_used := acsaf.nfi;

        FOR tmp_xml IN SELECT UNNEST(XPATH('//*[@tag="'||tag_used||'"]', marcxml::XML)) LOOP
            heading_text := '';

            FOR sf IN SELECT * FROM regexp_split_to_table(acsaf.sf_list,'') LOOP
                heading_text := heading_text || COALESCE( ' ' || oils_xpath_string('//*[@code="'||sf||'"]',tmp_xml::TEXT), '');
            END LOOP;

            heading_text := public.naco_normalize(heading_text);
            
            IF nfi_used IS NOT NULL THEN

                sort_text := SUBSTRING(
                    heading_text FROM
                    COALESCE(
                        NULLIF(
                            REGEXP_REPLACE(
                                oils_xpath_string('//*[@tag="'||tag_used||'"]/@ind'||nfi_used, marcxml),
                                $$\D+$$,
                                '',
                                'g'
                            ),
                            ''
                        )::INT,
                        0
                    ) + 1
                );

            ELSE
                sort_text := heading_text;
            END IF;

            IF heading_text IS NOT NULL AND heading_text <> '' THEN
                res.value := heading_text;
                res.sort_value := sort_text;
                RETURN NEXT res;
            END IF;

        END LOOP;

    END LOOP;

    RETURN;
END;
$func$ LANGUAGE PLPGSQL IMMUTABLE;

-- Support function used to find the pivot for alpha-heading-browse style searching
DROP FUNCTION IF EXISTS authority.simple_heading_find_pivot( a INT[], q TEXT );
CREATE OR REPLACE FUNCTION authority.simple_heading_find_pivot( a INT[], q TEXT ) RETURNS TEXT AS $$
DECLARE
    sort_value_row  RECORD;
    value_row       RECORD;
    t_term          TEXT;
BEGIN

    t_term := public.naco_normalize(q);

    SELECT  CASE WHEN ash.sort_value LIKE t_term || '%' THEN 1 ELSE 0 END
                + CASE WHEN ash.value LIKE t_term || '%' THEN 1 ELSE 0 END AS rank,
            ash.sort_value
      INTO  sort_value_row
      FROM  authority.simple_heading ash
      WHERE ash.atag = ANY (a)
            AND ash.sort_value >= t_term
      ORDER BY rank DESC, ash.sort_value
      LIMIT 1;

    SELECT  CASE WHEN ash.sort_value LIKE t_term || '%' THEN 1 ELSE 0 END
                + CASE WHEN ash.value LIKE t_term || '%' THEN 1 ELSE 0 END AS rank,
            ash.sort_value
      INTO  value_row
      FROM  authority.simple_heading ash
      WHERE ash.atag = ANY (a)
            AND ash.value >= t_term
      ORDER BY rank DESC, ash.sort_value
      LIMIT 1;

    IF value_row.rank > sort_value_row.rank THEN
        RETURN value_row.sort_value;
    ELSE
        RETURN sort_value_row.sort_value;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS  authority.simple_heading_browse_center( atag_list INT[], q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.simple_heading_browse_center( atag_list INT[], q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
DECLARE
    pivot_sort_value    TEXT;
    boffset             INT DEFAULT 0;
    aoffset             INT DEFAULT 0;
    blimit              INT DEFAULT 0;
    alimit              INT DEFAULT 0;
BEGIN

    pivot_sort_value := authority.simple_heading_find_pivot(atag_list,q);

    IF page = 0 THEN
        blimit := pagesize / 2;
        alimit := blimit;

        IF pagesize % 2 <> 0 THEN
            alimit := alimit + 1;
        END IF;
    ELSE
        blimit := pagesize;
        alimit := blimit;

        boffset := pagesize / 2;
        aoffset := boffset;

        IF pagesize % 2 <> 0 THEN
            boffset := boffset + 1;
        END IF;
    END IF;

    IF page <= 0 THEN
        RETURN QUERY
            -- "bottom" half of the browse results
            SELECT id FROM (
                SELECT  ash.id,
                        row_number() over ()
                  FROM  authority.simple_heading ash
                  WHERE ash.atag = ANY (atag_list)
                        AND ash.sort_value < pivot_sort_value
                  ORDER BY ash.sort_value DESC
                  LIMIT blimit
                  OFFSET ABS(page) * pagesize - boffset
            ) x ORDER BY row_number DESC;
    END IF;

    IF page >= 0 THEN
        RETURN QUERY
            -- "bottom" half of the browse results
            SELECT  ash.id
              FROM  authority.simple_heading ash
              WHERE ash.atag = ANY (atag_list)
                    AND ash.sort_value >= pivot_sort_value
              ORDER BY ash.sort_value
              LIMIT alimit
              OFFSET ABS(page) * pagesize - aoffset;
    END IF;
END;
$$ LANGUAGE PLPGSQL ROWS 10;

DROP FUNCTION IF EXISTS authority.simple_heading_browse_top( atag_list INT[], q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.simple_heading_browse_top( atag_list INT[], q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
DECLARE
    pivot_sort_value    TEXT;
BEGIN

    pivot_sort_value := authority.simple_heading_find_pivot(atag_list,q);

    IF page < 0 THEN
        RETURN QUERY
            -- "bottom" half of the browse results
            SELECT id FROM (
                SELECT  ash.id,
                        row_number() over ()
                  FROM  authority.simple_heading ash
                  WHERE ash.atag = ANY (atag_list)
                        AND ash.sort_value < pivot_sort_value
                  ORDER BY ash.sort_value DESC
                  LIMIT pagesize
                  OFFSET (ABS(page) - 1) * pagesize
            ) x ORDER BY row_number DESC;
    END IF;

    IF page >= 0 THEN
        RETURN QUERY
            -- "bottom" half of the browse results
            SELECT  ash.id
              FROM  authority.simple_heading ash
              WHERE ash.atag = ANY (atag_list)
                    AND ash.sort_value >= pivot_sort_value
              ORDER BY ash.sort_value
              LIMIT pagesize
              OFFSET ABS(page) * pagesize ;
    END IF;
END;
$$ LANGUAGE PLPGSQL ROWS 10;

DROP FUNCTION IF EXISTS authority.simple_heading_search_rank( atag_list INT[], q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.simple_heading_search_rank( atag_list INT[], q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT  ash.id
      FROM  authority.simple_heading ash,
            public.naco_normalize($2) t(term),
            plainto_tsquery('keyword'::regconfig,$2) ptsq(term)
      WHERE ash.atag = ANY ($1)
            AND ash.index_vector @@ ptsq.term
      ORDER BY ts_rank_cd(ash.index_vector,ptsq.term,14)::numeric
                    + CASE WHEN ash.sort_value LIKE t.term || '%' THEN 2 ELSE 0 END
                    + CASE WHEN ash.value LIKE t.term || '%' THEN 1 ELSE 0 END DESC
      LIMIT $4
      OFFSET $4 * $3;
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.simple_heading_search_heading( atag_list INT[], q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.simple_heading_search_heading( atag_list INT[], q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT  ash.id
      FROM  authority.simple_heading ash,
            public.naco_normalize($2) t(term),
            plainto_tsquery('keyword'::regconfig,$2) ptsq(term)
      WHERE ash.atag = ANY ($1)
            AND ash.index_vector @@ ptsq.term
      ORDER BY ash.sort_value
      LIMIT $4
      OFFSET $4 * $3;
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.axis_authority_tags(a TEXT);
CREATE OR REPLACE FUNCTION authority.axis_authority_tags(a TEXT) RETURNS INT[] AS $$
    SELECT ARRAY_ACCUM(field) FROM authority.browse_axis_authority_field_map WHERE axis = $1;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS authority.axis_authority_tags_refs(a TEXT);
CREATE OR REPLACE FUNCTION authority.axis_authority_tags_refs(a TEXT) RETURNS INT[] AS $$
    SELECT  ARRAY_CAT(
                ARRAY[a.field],
                (SELECT ARRAY_ACCUM(x.id) FROM authority.control_set_authority_field x WHERE x.main_entry = a.field)
            )
      FROM  authority.browse_axis_authority_field_map a
      WHERE axis = $1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS authority.btag_authority_tags(btag TEXT);
CREATE OR REPLACE FUNCTION authority.btag_authority_tags(btag TEXT) RETURNS INT[] AS $$
    SELECT ARRAY_ACCUM(authority_field) FROM authority.control_set_bib_field WHERE tag = $1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS authority.btag_authority_tags_refs(btag TEXT);
CREATE OR REPLACE FUNCTION authority.btag_authority_tags_refs(btag TEXT) RETURNS INT[] AS $$
    SELECT  ARRAY_CAT(
                ARRAY[a.authority_field],
                (SELECT ARRAY_ACCUM(x.id) FROM authority.control_set_authority_field x WHERE x.main_entry = a.authority_field)
            )
      FROM  authority.control_set_bib_field a
      WHERE a.tag = $1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS authority.atag_authority_tags(atag TEXT);
CREATE OR REPLACE FUNCTION authority.atag_authority_tags(atag TEXT) RETURNS INT[] AS $$
    SELECT ARRAY_ACCUM(id) FROM authority.control_set_authority_field WHERE tag = $1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS authority.atag_authority_tags_refs(atag TEXT);
CREATE OR REPLACE FUNCTION authority.atag_authority_tags_refs(atag TEXT) RETURNS INT[] AS $$
    SELECT  ARRAY_CAT(
                ARRAY[a.id],
                (SELECT ARRAY_ACCUM(x.id) FROM authority.control_set_authority_field x WHERE x.main_entry = a.id)
            )
      FROM  authority.control_set_authority_field a
      WHERE a.tag = $1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS authority.axis_browse_center( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.axis_browse_center( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.axis_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.btag_browse_center( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.btag_browse_center( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.btag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.atag_browse_center( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.atag_browse_center( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.atag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.axis_browse_center_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.axis_browse_center_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.axis_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.btag_browse_center_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.btag_browse_center_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.btag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.atag_browse_center_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.atag_browse_center_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.atag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.axis_browse_top( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.axis_browse_top( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.axis_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.btag_browse_top( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.btag_browse_top( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.btag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.atag_browse_top( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.atag_browse_top( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.atag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.axis_browse_top_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.axis_browse_top_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.axis_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.btag_browse_top_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.btag_browse_top_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.btag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.atag_browse_top_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.atag_browse_top_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.atag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.axis_search_rank( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.axis_search_rank( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.axis_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.btag_search_rank( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.btag_search_rank( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.btag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.atag_search_rank( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.atag_search_rank( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.atag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.axis_search_rank_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.axis_search_rank_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.axis_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.btag_search_rank_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.btag_search_rank_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.btag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS  authority.atag_search_rank_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.atag_search_rank_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.atag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.axis_search_heading( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.axis_search_heading( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.axis_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.btag_search_heading( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.btag_search_heading( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.btag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.atag_search_heading( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.atag_search_heading( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.atag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.axis_search_heading_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.axis_search_heading_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.axis_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.btag_search_heading_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.btag_search_heading_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.btag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

DROP FUNCTION IF EXISTS authority.atag_search_heading_refs( a TEXT, q TEXT, page INT, pagesize INT );
CREATE OR REPLACE FUNCTION authority.atag_search_heading_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.atag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

