-- Authority Schema Inits

CREATE OR REPLACE FUNCTION authority.flatten_marc ( rid BIGINT ) RETURNS SETOF authority.full_rec AS $func$
DECLARE
	auth	authority.record_entry%ROWTYPE;
	output	authority.full_rec%ROWTYPE;
	field	RECORD;
BEGIN
	SELECT INTO auth * FROM authority.record_entry WHERE id = rid;

	FOR field IN SELECT * FROM vandelay.flatten_marc( auth.marc ) LOOP
		output.record := rid;
		output.ind1 := field.ind1;
		output.ind2 := field.ind2;
		output.tag := field.tag;
		output.subfield := field.subfield;
		output.value := field.value;

		RETURN NEXT output;
	END LOOP;
END;
$func$ LANGUAGE PLPGSQL;

--  authority.control_set_authority_field does not exist
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

CREATE OR REPLACE FUNCTION authority.simple_normalize_heading( marcxml TEXT ) RETURNS TEXT AS $func$
    SELECT authority.normalize_heading($1, TRUE);
$func$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION authority.normalize_heading( marcxml TEXT ) RETURNS TEXT AS $func$
    SELECT authority.normalize_heading($1, FALSE);
$func$ LANGUAGE SQL IMMUTABLE;

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
 
CREATE OR REPLACE FUNCTION authority.generate_overlay_template ( BIGINT ) RETURNS TEXT AS $func$
    SELECT authority.generate_overlay_template( marc ) FROM authority.record_entry WHERE id = $1;
$func$ LANGUAGE SQL;

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

CREATE OR REPLACE FUNCTION authority.simple_normalize_heading( marcxml TEXT ) RETURNS TEXT AS $func$
    SELECT authority.normalize_heading($1, TRUE);
$func$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION authority.normalize_heading( marcxml TEXT ) RETURNS TEXT AS $func$
    SELECT authority.normalize_heading($1, FALSE);
$func$ LANGUAGE SQL IMMUTABLE;

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


CREATE OR REPLACE FUNCTION authority.axis_authority_tags(a TEXT) RETURNS INT[] AS $$
    SELECT ARRAY_ACCUM(field) FROM authority.browse_axis_authority_field_map WHERE axis = $1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION authority.axis_authority_tags_refs(a TEXT) RETURNS INT[] AS $$
    SELECT  ARRAY_CAT(
                ARRAY[a.field],
                (SELECT ARRAY_ACCUM(x.id) FROM authority.control_set_authority_field x WHERE x.main_entry = a.field)
            )
      FROM  authority.browse_axis_authority_field_map a
      WHERE axis = $1
$$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION authority.btag_authority_tags(btag TEXT) RETURNS INT[] AS $$
    SELECT ARRAY_ACCUM(authority_field) FROM authority.control_set_bib_field WHERE tag = $1
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION authority.btag_authority_tags_refs(btag TEXT) RETURNS INT[] AS $$
    SELECT  ARRAY_CAT(
                ARRAY[a.authority_field],
                (SELECT ARRAY_ACCUM(x.id) FROM authority.control_set_authority_field x WHERE x.main_entry = a.authority_field)
            )
      FROM  authority.control_set_bib_field a
      WHERE a.tag = $1
$$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION authority.atag_authority_tags(atag TEXT) RETURNS INT[] AS $$
    SELECT ARRAY_ACCUM(id) FROM authority.control_set_authority_field WHERE tag = $1
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION authority.atag_authority_tags_refs(atag TEXT) RETURNS INT[] AS $$
    SELECT  ARRAY_CAT(
                ARRAY[a.id],
                (SELECT ARRAY_ACCUM(x.id) FROM authority.control_set_authority_field x WHERE x.main_entry = a.id)
            )
      FROM  authority.control_set_authority_field a
      WHERE a.tag = $1
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION authority.axis_browse_center( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.axis_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.btag_browse_center( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.btag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.atag_browse_center( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.atag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.axis_browse_center_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.axis_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.btag_browse_center_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.btag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.atag_browse_center_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 9 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_center(authority.atag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;


CREATE OR REPLACE FUNCTION authority.axis_browse_top( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.axis_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.btag_browse_top( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.btag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.atag_browse_top( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.atag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.axis_browse_top_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.axis_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.btag_browse_top_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.btag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.atag_browse_top_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_browse_top(authority.atag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;


CREATE OR REPLACE FUNCTION authority.axis_search_rank( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.axis_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.btag_search_rank( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.btag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.atag_search_rank( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.atag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.axis_search_rank_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.axis_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.btag_search_rank_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.btag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.atag_search_rank_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_rank(authority.atag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;


CREATE OR REPLACE FUNCTION authority.axis_search_heading( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.axis_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.btag_search_heading( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.btag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.atag_search_heading( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.atag_authority_tags($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.axis_search_heading_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.axis_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.btag_search_heading_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.btag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

CREATE OR REPLACE FUNCTION authority.atag_search_heading_refs( a TEXT, q TEXT, page INT DEFAULT 0, pagesize INT DEFAULT 10 ) RETURNS SETOF BIGINT AS $$
    SELECT * FROM authority.simple_heading_search_heading(authority.atag_authority_tags_refs($1), $2, $3, $4)
$$ LANGUAGE SQL ROWS 10;

 -- Move after function creation.
CREATE INDEX by_heading ON authority.record_entry (authority.simple_normalize_heading(marc)) WHERE deleted IS FALSE or deleted = FALSE;
