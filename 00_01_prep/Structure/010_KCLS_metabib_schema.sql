-- Metabib Schema Inits

-- Function script /start
DROP TABLE IF EXISTS metabib.normalized_title_field_entry;
CREATE TABLE metabib.normalized_title_field_entry
(
  id bigint NOT NULL,
  source bigint,
  value text,
  ind text,
  CONSTRAINT normalized_title_field_entry_pkey PRIMARY KEY (id ),
  CONSTRAINT "normalized_title_to_ title_field_entry_FK" FOREIGN KEY (id)
      REFERENCES metabib.title_field_entry (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX normalized_title_field_entry_gist_trgm
  ON metabib.normalized_title_field_entry
  USING gist
  (value COLLATE pg_catalog."C" gist_trgm_ops);

DROP INDEX IF EXISTS metabib.normalized_title_field_entry_gist_trgm;
CREATE INDEX normalized_remove_insignificants_title_field_entry_gist_trgm
  ON metabib.normalized_title_field_entry
  USING gist
  (remove_insignificants(value) COLLATE pg_catalog."C" gist_trgm_ops);
CREATE INDEX "fki_normalized_title_to_ title_field_entry_FK"
  ON metabib.normalized_title_field_entry
  USING btree
  (id );

CREATE TABLE metabib.browse_entry_def_map (
    id BIGSERIAL PRIMARY KEY,
    entry BIGINT REFERENCES metabib.browse_entry (id),
    def INT REFERENCES config.metabib_field (id),
    source BIGINT REFERENCES biblio.record_entry (id)
);

DROP FUNCTION IF EXISTS metabib.browse_normalize(facet_text TEXT, mapped_field INT);
CREATE OR REPLACE FUNCTION metabib.browse_normalize(facet_text TEXT, mapped_field INT) RETURNS TEXT AS $$
DECLARE
    normalizer  RECORD;
BEGIN

    FOR normalizer IN
        SELECT  n.func AS func,
                n.param_count AS param_count,
                m.params AS params
          FROM  config.index_normalizer n
                JOIN config.metabib_field_index_norm_map m ON (m.norm = n.id)
          WHERE m.field = mapped_field AND m.pos < 0
          ORDER BY m.pos LOOP

            EXECUTE 'SELECT ' || normalizer.func || '(' ||
                quote_literal( facet_text ) ||
                CASE
                    WHEN normalizer.param_count > 0
                        THEN ',' || REPLACE(REPLACE(BTRIM(normalizer.params,'[]'),E'\'',E'\\\''),E'"',E'\'') --'
                        ELSE ''
                    END ||
                ')' INTO facet_text;

    END LOOP;

    RETURN facet_text;
END;

$$ LANGUAGE PLPGSQL;

-- New function def
DROP FUNCTION IF EXISTS metabib.reingest_metabib_field_entries( bib_id BIGINT, skip_facet BOOL, skip_browse BOOL, skip_search BOOL );
CREATE OR REPLACE FUNCTION metabib.reingest_metabib_field_entries( bib_id BIGINT, skip_facet BOOL DEFAULT FALSE, skip_browse BOOL DEFAULT FALSE, skip_search BOOL DEFAULT FALSE ) RETURNS VOID AS $func$
DECLARE
    fclass          RECORD;
    ind_data        metabib.field_entry_template%ROWTYPE;
    mbe_row         metabib.browse_entry%ROWTYPE;
    mbe_id          BIGINT;
    normalized_value    TEXT;
BEGIN
    PERFORM * FROM config.internal_flag WHERE name = 'ingest.assume_inserts_only' AND enabled;
    IF NOT FOUND THEN
        IF NOT skip_search THEN
            FOR fclass IN SELECT * FROM config.metabib_class LOOP
                -- RAISE NOTICE 'Emptying out %', fclass.name;
                EXECUTE $$DELETE FROM metabib.$$ || fclass.name || $$_field_entry WHERE source = $$ || bib_id;
            END LOOP;
        END IF;
        IF NOT skip_facet THEN
            DELETE FROM metabib.facet_entry WHERE source = bib_id;
        END IF;
        IF NOT skip_browse THEN
            DELETE FROM metabib.browse_entry_def_map WHERE source = bib_id;
        END IF;
    END IF;

    FOR ind_data IN SELECT * FROM biblio.extract_metabib_field_entry( bib_id ) LOOP
        IF ind_data.field < 0 THEN
            ind_data.field = -1 * ind_data.field;
        END IF;

        IF ind_data.facet_field AND NOT skip_facet THEN
            INSERT INTO metabib.facet_entry (field, source, value)
                VALUES (ind_data.field, ind_data.source, ind_data.value);
        END IF;

        IF ind_data.browse_field AND NOT skip_browse THEN
            -- A caveat about this SELECT: this should take care of replacing
            -- old mbe rows when data changes, but not if normalization (by
            -- which I mean specifically the output of
            -- evergreen.oils_tsearch2()) changes.  It may or may not be
            -- expensive to add a comparison of index_vector to index_vector
            -- to the WHERE clause below.
            normalized_value := metabib.browse_normalize(
                ind_data.value, ind_data.field
            );

            SELECT INTO mbe_row * FROM metabib.browse_entry WHERE value = normalized_value;
            IF FOUND THEN
                mbe_id := mbe_row.id;
            ELSE
                INSERT INTO metabib.browse_entry (value) VALUES (normalized_value);
                mbe_id := CURRVAL('metabib.browse_entry_id_seq'::REGCLASS);
            END IF;

            INSERT INTO metabib.browse_entry_def_map (entry, def, source)
                VALUES (mbe_id, ind_data.field, ind_data.source);
        END IF;

        IF ind_data.search_field AND NOT skip_search THEN
            EXECUTE $$
                INSERT INTO metabib.$$ || ind_data.field_class || $$_field_entry (field, source, value)
                    VALUES ($$ ||
                        quote_literal(ind_data.field) || $$, $$ ||
                        quote_literal(ind_data.source) || $$, $$ ||
                        quote_literal(ind_data.value) ||
                    $$);$$;
        END IF;

    END LOOP;

    RETURN;
END;
$func$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS metabib.normalized_field_entry_view();
CREATE OR REPLACE FUNCTION metabib.normalized_field_entry_view()
  RETURNS trigger AS
$BODY$

DECLARE
	norm_table		text	:= 	TG_TABLE_SCHEMA || '.normalized_' || TG_TABLE_NAME;
	temp_id			bigint;
BEGIN

IF(TG_OP = 'UPDATE') THEN

EXECUTE 'SELECT id FROM '||norm_table||' WHERE id = '||NEW.id||';' INTO temp_id;

	IF(temp_id IS NOT NULL) THEN
		EXECUTE 'UPDATE '||norm_table||' 
		SET value = '''||search_normalize(NEW.value)||''', ind = get_ind('||NEW.source||','||NEW.field||'), source = '||NEW.source||' WHERE id = '||NEW.id||';';
	ELSE
		EXECUTE 'INSERT INTO '||norm_table||' VALUES ( '||NEW.id||','||NEW.source||', '''||search_normalize(NEW.value)||''', get_ind('||NEW.source||', '||NEW.field||') );';
	END IF;
ELSIF(TG_OP = 'INSERT') THEN

	EXECUTE 'INSERT INTO '||norm_table||' VALUES ( '||NEW.id||','||NEW.source||', '''||search_normalize(NEW.value)||''', get_ind('||NEW.source||', '||NEW.field||') );';

END IF;

RETURN NULL;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function script /end


CREATE TRIGGER metabib_browse_entry_fti_trigger
    BEFORE INSERT OR UPDATE ON metabib.browse_entry
    FOR EACH ROW EXECUTE PROCEDURE oils_tsearch2('keyword');



-- We need thes to make the autosuggest limiting joins fast
CREATE INDEX browse_entry_def_map_def_idx ON metabib.browse_entry_def_map (def);
CREATE INDEX browse_entry_def_map_entry_idx ON metabib.browse_entry_def_map (entry);
CREATE INDEX browse_entry_def_map_source_idx ON metabib.browse_entry_def_map (source);


DROP TABLE IF EXISTS metabib.normalized_subject_field_entry;
CREATE TABLE metabib.normalized_subject_field_entry
(
  id bigint NOT NULL,
  source bigint,
  value text,
  ind text,
  CONSTRAINT normalized_subject_field_entry_pkey PRIMARY KEY (id ),
  CONSTRAINT "normalized_subject_to_ subject_field_entry_FK" FOREIGN KEY (id)
      REFERENCES metabib.subject_field_entry (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

DROP INDEX IF EXISTS metabib.normalized_subject_field_entry_gist_trgm;
CREATE INDEX normalized_subject_field_entry_gist_trgm
  ON metabib.normalized_subject_field_entry
  USING gist
  (value COLLATE pg_catalog."C" gist_trgm_ops);

DROP INDEX IF EXISTS metabib.normalized_remove_insignificants_subject_field_entry_gist_trgm;
CREATE INDEX normalized_remove_insignificants_subject_field_entry_gist_trgm
  ON metabib.normalized_subject_field_entry
  USING gist
  (remove_insignificants(value) COLLATE pg_catalog."C" gist_trgm_ops);
  
CREATE INDEX "fki_normalized_subject_to_ subject_field_entry_FK"
  ON metabib.normalized_subject_field_entry
  USING btree
  (id );

DROP TABLE IF EXISTS metabib.normalized_author_field_entry;
CREATE TABLE metabib.normalized_author_field_entry
(
  id bigint NOT NULL,
  source bigint,
  value text,
  ind text,
  CONSTRAINT normalized_author_field_entry_pkey PRIMARY KEY (id ),
  CONSTRAINT "normalized_author_to_ author_field_entry_FK" FOREIGN KEY (id)
      REFERENCES metabib.author_field_entry (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX normalized_author_field_entry_gist_trgm
  ON metabib.normalized_author_field_entry
  USING gist
  (value COLLATE pg_catalog."C" gist_trgm_ops);
  
CREATE INDEX normalized_remove_insignificants_author_field_entry_gist_trgm
  ON metabib.normalized_author_field_entry
  USING gist
  (remove_insignificants(value) COLLATE pg_catalog."C" gist_trgm_ops);

CREATE INDEX "fki_normalized_author_to_ author_field_entry_FK"
  ON metabib.normalized_author_field_entry
  USING btree
  (id );

DROP TABLE IF EXISTS metabib.normalized_series_field_entry;
CREATE TABLE metabib.normalized_series_field_entry
(
  id bigint NOT NULL,
  source bigint,
  value text,
  ind text,
  CONSTRAINT normalized_series_field_entry_pkey PRIMARY KEY (id ),
  CONSTRAINT "normalized_series_to_ series_field_entry_FK" FOREIGN KEY (id)
      REFERENCES metabib.series_field_entry (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

DROP INDEX IF EXISTS metabib.normalized_series_field_entry_gist_trgm;
CREATE INDEX normalized_series_field_entry_gist_trgm
  ON metabib.normalized_series_field_entry
  USING gist
  (value COLLATE pg_catalog."C" gist_trgm_ops);

DROP INDEX IF EXISTS metabib.normalized_remove_insignificants_series_field_entry_gist_trgm;
CREATE INDEX normalized_remove_insignificants_series_field_entry_gist_trgm
  ON metabib.normalized_series_field_entry
  USING gist
  (remove_insignificants(value) COLLATE pg_catalog."C" gist_trgm_ops);

CREATE INDEX "fki_normalized_series_to_ series_field_entry_FK"
  ON metabib.normalized_series_field_entry
  USING btree
  (id );
  
DROP TABLE IF EXISTS metabib.normalized_keyword_field_entry;
CREATE TABLE metabib.normalized_keyword_field_entry
(
  id bigint NOT NULL,
  source bigint,
  value text,
  ind text,
  CONSTRAINT normalized_keyword_field_entry_pkey PRIMARY KEY (id ),
  CONSTRAINT "normalized_keyword_to_ keyword_field_entry_FK" FOREIGN KEY (id)
      REFERENCES metabib.keyword_field_entry (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX "fki_normalized_keyword_to_ keyword_field_entry_FK"
  ON metabib.normalized_keyword_field_entry
  USING btree
  (id );
 
 UPDATE config.coded_value_map
SET code = code WHERE 1=1;

CREATE INDEX metabib_full_rec_isxn_caseless_idx
    ON metabib.real_full_rec (LOWER(value))
    WHERE tag IN ('020', '022', '024');
	
-- This mimics a specific part of QueryParser, turning the first part of a
-- classed search (search_class) into a set of classes and possibly fields.
-- search_class might look like "author" or "title|proper" or "ti|uniform"
-- or "au" or "au|corporate|personal" or anything like that, where the first
-- element of the list you get by separating on the "|" character is either
-- a registered class (config.metabib_class) or an alias
-- (config.metabib_search_alias), and the rest of any such elements are
-- fields (config.metabib_field).
DROP FUNCTION IF EXISTS  metabib.search_class_to_registered_components(search_class TEXT);
CREATE OR REPLACE
    FUNCTION metabib.search_class_to_registered_components(search_class TEXT)
    RETURNS SETOF RECORD AS $func$
DECLARE
    search_parts        TEXT[];
    field_name          TEXT;
    search_part_count   INTEGER;
    rec                 RECORD;
    registered_class    config.metabib_class%ROWTYPE;
    registered_alias    config.metabib_search_alias%ROWTYPE;
    registered_field    config.metabib_field%ROWTYPE;
BEGIN
    search_parts := REGEXP_SPLIT_TO_ARRAY(search_class, E'\\|');

    search_part_count := ARRAY_LENGTH(search_parts, 1);
    IF search_part_count = 0 THEN
        RETURN;
    ELSE
        SELECT INTO registered_class
            * FROM config.metabib_class WHERE name = search_parts[1];
        IF FOUND THEN
            IF search_part_count < 2 THEN   -- all fields
                rec := (registered_class.name, NULL::INTEGER);
                RETURN NEXT rec;
                RETURN; -- done
            END IF;
            FOR field_name IN SELECT *
                FROM UNNEST(search_parts[2:search_part_count]) LOOP
                SELECT INTO registered_field
                    * FROM config.metabib_field
                    WHERE name = field_name AND
                        field_class = registered_class.name;
                IF FOUND THEN
                    rec := (registered_class.name, registered_field.id);
                    RETURN NEXT rec;
                END IF;
            END LOOP;
        ELSE
            -- maybe we have an alias?
            SELECT INTO registered_alias
                * FROM config.metabib_search_alias WHERE alias=search_parts[1];
            IF NOT FOUND THEN
                RETURN;
            ELSE
                IF search_part_count < 2 THEN   -- return w/e the alias says
                    rec := (
                        registered_alias.field_class, registered_alias.field
                    );
                    RETURN NEXT rec;
                    RETURN; -- done
                ELSE
                    FOR field_name IN SELECT *
                        FROM UNNEST(search_parts[2:search_part_count]) LOOP
                        SELECT INTO registered_field
                            * FROM config.metabib_field
                            WHERE name = field_name AND
                                field_class = registered_alias.field_class;
                        IF FOUND THEN
                            rec := (
                                registered_alias.field_class,
                                registered_field.id
                            );
                            RETURN NEXT rec;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END IF;
    END IF;
END;
$func$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS metabib.suggest_browse_entries(
        query_text      TEXT,   -- 'foo' or 'foo & ba:*',ready for to_tsquery()
        search_class    TEXT,   -- 'alias' or 'class' or 'class|field..', etc
        headline_opts   TEXT,   -- markup options for ts_headline()
        visibility_org  INTEGER,-- null if you don't want opac visibility test
        query_limit     INTEGER,-- use in LIMIT clause of interal query
        normalization   INTEGER -- argument to TS_RANK_CD()
    ) ;
CREATE OR REPLACE
    FUNCTION metabib.suggest_browse_entries(
        query_text      TEXT,   -- 'foo' or 'foo & ba:*',ready for to_tsquery()
        search_class    TEXT,   -- 'alias' or 'class' or 'class|field..', etc
        headline_opts   TEXT,   -- markup options for ts_headline()
        visibility_org  INTEGER,-- null if you don't want opac visibility test
        query_limit     INTEGER,-- use in LIMIT clause of interal query
        normalization   INTEGER -- argument to TS_RANK_CD()
    ) RETURNS TABLE (
        value                   TEXT,   -- plain
        field                   INTEGER,
        bouyant_and_class_match BOOL,
        field_match             BOOL,
        field_weight            INTEGER,
        rank                    REAL,
        bouyant                 BOOL,
        match                   TEXT    -- marked up
    ) AS $func$
DECLARE
    query                   TSQUERY;
    opac_visibility_join    TEXT;
    search_class_join       TEXT;
    r_fields                RECORD;
BEGIN
    query := TO_TSQUERY('keyword', query_text);

    IF visibility_org IS NOT NULL THEN
        opac_visibility_join := '
    JOIN asset.opac_visible_copies aovc ON (
        aovc.record = mbedm.source AND
        aovc.circ_lib IN (SELECT id FROM actor.org_unit_descendants($4))
    )';
    ELSE
        opac_visibility_join := '';
    END IF;

    -- The following determines whether we only provide suggestsons matching
    -- the user's selected search_class, or whether we show other suggestions
    -- too. The reason for MIN() is that for search_classes like
    -- 'title|proper|uniform' you would otherwise get multiple rows.  The
    -- implication is that if title as a class doesn't have restrict,
    -- nor does the proper field, but the uniform field does, you're going
    -- to get 'false' for your overall evaluation of 'should we restrict?'
    -- To invert that, change from MIN() to MAX().

    SELECT
        INTO r_fields
            MIN(cmc.restrict::INT) AS restrict_class,
            MIN(cmf.restrict::INT) AS restrict_field
        FROM metabib.search_class_to_registered_components(search_class)
            AS _registered (field_class TEXT, field INT)
        JOIN
            config.metabib_class cmc ON (cmc.name = _registered.field_class)
        LEFT JOIN
            config.metabib_field cmf ON (cmf.id = _registered.field);

    -- evaluate 'should we restrict?'
    IF r_fields.restrict_field::BOOL OR r_fields.restrict_class::BOOL THEN
        search_class_join := '
    JOIN
        metabib.search_class_to_registered_components($2)
        AS _registered (field_class TEXT, field INT) ON (
            (_registered.field IS NULL AND
                _registered.field_class = cmf.field_class) OR
            (_registered.field = cmf.id)
        )
    ';
    ELSE
        search_class_join := '
    LEFT JOIN
        metabib.search_class_to_registered_components($2)
        AS _registered (field_class TEXT, field INT) ON (
            _registered.field_class = cmc.name
        )
    ';
    END IF;

    RETURN QUERY EXECUTE 'SELECT *, TS_HEADLINE(value, $1, $3) FROM (SELECT DISTINCT
        mbe.value,
        cmf.id,
        cmc.bouyant AND _registered.field_class IS NOT NULL,
        _registered.field = cmf.id,
        cmf.weight,
        TS_RANK_CD(mbe.index_vector, $1, $6),
        cmc.bouyant
    FROM metabib.browse_entry_def_map mbedm
    JOIN metabib.browse_entry mbe ON (mbe.id = mbedm.entry)
    JOIN config.metabib_field cmf ON (cmf.id = mbedm.def)
    JOIN config.metabib_class cmc ON (cmf.field_class = cmc.name)
    '  || search_class_join || opac_visibility_join ||
    ' WHERE $1 @@ mbe.index_vector
    ORDER BY 3 DESC, 4 DESC NULLS LAST, 5 DESC, 6 DESC, 7 DESC, 1 ASC
    LIMIT $5) x
    ORDER BY 3 DESC, 4 DESC NULLS LAST, 5 DESC, 6 DESC, 7 DESC, 1 ASC
    '   -- sic, repeat the order by clause in the outer select too
    USING
        query, search_class, headline_opts,
        visibility_org, query_limit, normalization
        ;

    -- sort order:
    --  bouyant AND chosen class = match class
    --  chosen field = match field
    --  field weight
    --  rank
    --  bouyancy
    --  value itself

END;
$func$ LANGUAGE PLPGSQL;

-- default to a space joiner

DROP FUNCTION IF EXISTS metabib.reingest_metabib_field_entries( bib_id BIGINT );
CREATE OR REPLACE FUNCTION metabib.reingest_metabib_field_entries( bib_id BIGINT ) RETURNS VOID AS $func$
DECLARE
    fclass          RECORD;
    ind_data        metabib.field_entry_template%ROWTYPE;
    mbe_row         metabib.browse_entry%ROWTYPE;
    mbe_id          BIGINT;
BEGIN
    PERFORM * FROM config.internal_flag WHERE name = 'ingest.assume_inserts_only' AND enabled;
    IF NOT FOUND THEN
        FOR fclass IN SELECT * FROM config.metabib_class LOOP
            -- RAISE NOTICE 'Emptying out %', fclass.name;
            EXECUTE $$DELETE FROM metabib.$$ || fclass.name || $$_field_entry WHERE source = $$ || bib_id;
        END LOOP;
        DELETE FROM metabib.facet_entry WHERE source = bib_id;
        DELETE FROM metabib.browse_entry_def_map WHERE source = bib_id;
    END IF;

    FOR ind_data IN SELECT * FROM biblio.extract_metabib_field_entry( bib_id ) LOOP
        IF ind_data.field < 0 THEN
            ind_data.field = -1 * ind_data.field;
        END IF;

        IF ind_data.facet_field THEN
            INSERT INTO metabib.facet_entry (field, source, value)
                VALUES (ind_data.field, ind_data.source, ind_data.value);
        END IF;

        IF ind_data.browse_field THEN
            SELECT INTO mbe_row * FROM metabib.browse_entry WHERE value = ind_data.value;
            IF FOUND THEN
                mbe_id := mbe_row.id;
            ELSE
                INSERT INTO metabib.browse_entry (value) VALUES
                    (metabib.browse_normalize(ind_data.value, ind_data.field));
                mbe_id := CURRVAL('metabib.browse_entry_id_seq'::REGCLASS);
            END IF;

            INSERT INTO metabib.browse_entry_def_map (entry, def, source)
                VALUES (mbe_id, ind_data.field, ind_data.source);
        END IF;

        IF ind_data.search_field THEN
            EXECUTE $$
                INSERT INTO metabib.$$ || ind_data.field_class || $$_field_entry (field, source, value)
                    VALUES ($$ ||
                        quote_literal(ind_data.field) || $$, $$ ||
                        quote_literal(ind_data.source) || $$, $$ ||
                        quote_literal(ind_data.value) ||
                    $$);$$;
        END IF;

    END LOOP;

    RETURN;
END;
$func$ LANGUAGE PLPGSQL;

-- Given a string such as a user might type into a search box, prepare
-- two changed variants for TO_TSQUERY(). See
-- http://www.postgresql.org/docs/9.0/static/textsearch-controls.html
-- The first variant is normalized to match indexed documents regardless
-- of diacritics.  The second variant keeps its diacritics for proper
-- highlighting via TS_HEADLINE().
DROP FUNCTION IF EXISTS metabib.autosuggest_prepare_tsquery(orig TEXT);
CREATE OR REPLACE
    FUNCTION metabib.autosuggest_prepare_tsquery(orig TEXT) RETURNS TEXT[] AS
$$
DECLARE
    orig_ended_in_space     BOOLEAN;
    result                  RECORD;
    plain                   TEXT;
    normalized              TEXT;
BEGIN
    orig_ended_in_space := orig ~ E'\\s$';

    orig := ARRAY_TO_STRING(
        evergreen.regexp_split_to_array(orig, E'\\W+'), ' '
    );

    normalized := public.search_normalize(orig); -- also trim()s
    plain := trim(orig);

    IF NOT orig_ended_in_space THEN
        plain := plain || ':*';
        normalized := normalized || ':*';
    END IF;

    plain := ARRAY_TO_STRING(
        evergreen.regexp_split_to_array(plain, E'\\s+'), ' & '
    );
    normalized := ARRAY_TO_STRING(
        evergreen.regexp_split_to_array(normalized, E'\\s+'), ' & '
    );

    RETURN ARRAY[normalized, plain];
END;
$$ LANGUAGE PLPGSQL;


-- Definition of OUT parameters changes, so must drop first
DROP FUNCTION IF EXISTS metabib.suggest_browse_entries (TEXT, TEXT, TEXT, INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE
    FUNCTION metabib.suggest_browse_entries(
        raw_query_text  TEXT,   -- actually typed by humans at the UI level
        search_class    TEXT,   -- 'alias' or 'class' or 'class|field..', etc
        headline_opts   TEXT,   -- markup options for ts_headline()
        visibility_org  INTEGER,-- null if you don't want opac visibility test
        query_limit     INTEGER,-- use in LIMIT clause of interal query
        normalization   INTEGER -- argument to TS_RANK_CD()
    ) RETURNS TABLE (
        value                   TEXT,   -- plain
        field                   INTEGER,
        buoyant_and_class_match BOOL,
        field_match             BOOL,
        field_weight            INTEGER,
        rank                    REAL,
        buoyant                 BOOL,
        match                   TEXT    -- marked up
    ) AS $func$
DECLARE
    prepared_query_texts    TEXT[];
    query                   TSQUERY;
    plain_query             TSQUERY;
    opac_visibility_join    TEXT;
    search_class_join       TEXT;
    r_fields                RECORD;
BEGIN
    prepared_query_texts := metabib.autosuggest_prepare_tsquery(raw_query_text);

    query := TO_TSQUERY('keyword', prepared_query_texts[1]);
    plain_query := TO_TSQUERY('keyword', prepared_query_texts[2]);

    IF visibility_org IS NOT NULL THEN
        opac_visibility_join := '
    JOIN asset.opac_visible_copies aovc ON (
        aovc.record = mbedm.source AND
        aovc.circ_lib IN (SELECT id FROM actor.org_unit_descendants($4))
    )';
    ELSE
        opac_visibility_join := '';
    END IF;

    -- The following determines whether we only provide suggestsons matching
    -- the user's selected search_class, or whether we show other suggestions
    -- too. The reason for MIN() is that for search_classes like
    -- 'title|proper|uniform' you would otherwise get multiple rows.  The
    -- implication is that if title as a class doesn't have restrict,
    -- nor does the proper field, but the uniform field does, you're going
    -- to get 'false' for your overall evaluation of 'should we restrict?'
    -- To invert that, change from MIN() to MAX().

    SELECT
        INTO r_fields
            MIN(cmc.restrict::INT) AS restrict_class,
            MIN(cmf.restrict::INT) AS restrict_field
        FROM metabib.search_class_to_registered_components(search_class)
            AS _registered (field_class TEXT, field INT)
        JOIN
            config.metabib_class cmc ON (cmc.name = _registered.field_class)
        LEFT JOIN
            config.metabib_field cmf ON (cmf.id = _registered.field);

    -- evaluate 'should we restrict?'
    IF r_fields.restrict_field::BOOL OR r_fields.restrict_class::BOOL THEN
        search_class_join := '
    JOIN
        metabib.search_class_to_registered_components($2)
        AS _registered (field_class TEXT, field INT) ON (
            (_registered.field IS NULL AND
                _registered.field_class = cmf.field_class) OR
            (_registered.field = cmf.id)
        )
    ';
    ELSE
        search_class_join := '
    LEFT JOIN
        metabib.search_class_to_registered_components($2)
        AS _registered (field_class TEXT, field INT) ON (
            _registered.field_class = cmc.name
        )
    ';
    END IF;

    RETURN QUERY EXECUTE 'SELECT *, TS_HEADLINE(value, $7, $3) FROM (SELECT DISTINCT
        mbe.value,
        cmf.id,
        cmc.buoyant AND _registered.field_class IS NOT NULL,
        _registered.field = cmf.id,
        cmf.weight,
        TS_RANK_CD(mbe.index_vector, $1, $6),
        cmc.buoyant
    FROM metabib.browse_entry_def_map mbedm
    JOIN metabib.browse_entry mbe ON (mbe.id = mbedm.entry)
    JOIN config.metabib_field cmf ON (cmf.id = mbedm.def)
    JOIN config.metabib_class cmc ON (cmf.field_class = cmc.name)
    '  || search_class_join || opac_visibility_join ||
    ' WHERE $1 @@ mbe.index_vector
    ORDER BY 3 DESC, 4 DESC NULLS LAST, 5 DESC, 6 DESC, 7 DESC, 1 ASC
    LIMIT $5) x
    ORDER BY 3 DESC, 4 DESC NULLS LAST, 5 DESC, 6 DESC, 7 DESC, 1 ASC
    '   -- sic, repeat the order by clause in the outer select too
    USING
        query, search_class, headline_opts,
        visibility_org, query_limit, normalization, plain_query
        ;

    -- sort order:
    --  buoyant AND chosen class = match class
    --  chosen field = match field
    --  field weight
    --  rank
    --  buoyancy
    --  value itself

END;
$func$ LANGUAGE PLPGSQL;

-- In practice this will always be ~1 row, and the default of 1000 causes terrible plans
ALTER FUNCTION metabib.search_class_to_registered_components(text) ROWS 1;

-- Reworking of the generated query to act in a sane manner in the face of large datasets
CREATE OR REPLACE
    FUNCTION metabib.suggest_browse_entries(
        raw_query_text  TEXT,   -- actually typed by humans at the UI level
        search_class    TEXT,   -- 'alias' or 'class' or 'class|field..', etc
        headline_opts   TEXT,   -- markup options for ts_headline()
        visibility_org  INTEGER,-- null if you don't want opac visibility test
        query_limit     INTEGER,-- use in LIMIT clause of interal query
        normalization   INTEGER -- argument to TS_RANK_CD()
    ) RETURNS TABLE (
        value                   TEXT,   -- plain
        field                   INTEGER,
        buoyant_and_class_match BOOL,
        field_match             BOOL,
        field_weight            INTEGER,
        rank                    REAL,
        buoyant                 BOOL,
        match                   TEXT    -- marked up
    ) AS $func$
DECLARE
    prepared_query_texts    TEXT[];
    query                   TSQUERY;
    plain_query             TSQUERY;
    opac_visibility_join    TEXT;
    search_class_join       TEXT;
    r_fields                RECORD;
BEGIN
    prepared_query_texts := metabib.autosuggest_prepare_tsquery(raw_query_text);

    query := TO_TSQUERY('keyword', prepared_query_texts[1]);
    plain_query := TO_TSQUERY('keyword', prepared_query_texts[2]);

    IF visibility_org IS NOT NULL THEN
        opac_visibility_join := '
    JOIN asset.opac_visible_copies aovc ON (
        aovc.record = x.source AND
        aovc.circ_lib IN (SELECT id FROM actor.org_unit_descendants($4))
    )';
    ELSE
        opac_visibility_join := '';
    END IF;

    -- The following determines whether we only provide suggestsons matching
    -- the user's selected search_class, or whether we show other suggestions
    -- too. The reason for MIN() is that for search_classes like
    -- 'title|proper|uniform' you would otherwise get multiple rows.  The
    -- implication is that if title as a class doesn't have restrict,
    -- nor does the proper field, but the uniform field does, you're going
    -- to get 'false' for your overall evaluation of 'should we restrict?'
    -- To invert that, change from MIN() to MAX().

    SELECT
        INTO r_fields
            MIN(cmc.restrict::INT) AS restrict_class,
            MIN(cmf.restrict::INT) AS restrict_field
        FROM metabib.search_class_to_registered_components(search_class)
            AS _registered (field_class TEXT, field INT)
        JOIN
            config.metabib_class cmc ON (cmc.name = _registered.field_class)
        LEFT JOIN
            config.metabib_field cmf ON (cmf.id = _registered.field);

    -- evaluate 'should we restrict?'
    IF r_fields.restrict_field::BOOL OR r_fields.restrict_class::BOOL THEN
        search_class_join := '
    JOIN
        metabib.search_class_to_registered_components($2)
        AS _registered (field_class TEXT, field INT) ON (
            (_registered.field IS NULL AND
                _registered.field_class = cmf.field_class) OR
            (_registered.field = cmf.id)
        )
    ';
    ELSE
        search_class_join := '
    LEFT JOIN
        metabib.search_class_to_registered_components($2)
        AS _registered (field_class TEXT, field INT) ON (
            _registered.field_class = cmc.name
        )
    ';
    END IF;

    RETURN QUERY EXECUTE '
SELECT  DISTINCT
        x.value,
        x.id,
        x.push,
        x.restrict,
        x.weight,
        x.ts_rank_cd,
        x.buoyant,
        TS_HEADLINE(value, $7, $3)
  FROM  (SELECT DISTINCT
                mbe.value,
                cmf.id,
                cmc.buoyant AND _registered.field_class IS NOT NULL AS push,
                _registered.field = cmf.id AS restrict,
                cmf.weight,
                TS_RANK_CD(mbe.index_vector, $1, $6),
                cmc.buoyant,
                mbedm.source
          FROM  metabib.browse_entry_def_map mbedm

                -- Start with a pre-limited set of 10k possible suggestions. More than that is not going to be useful anyway
                JOIN (SELECT * FROM metabib.browse_entry WHERE index_vector @@ $1 LIMIT 10000) mbe ON (mbe.id = mbedm.entry)

                JOIN config.metabib_field cmf ON (cmf.id = mbedm.def)
                JOIN config.metabib_class cmc ON (cmf.field_class = cmc.name)
                '  || search_class_join || '
          ORDER BY 3 DESC, 4 DESC NULLS LAST, 5 DESC, 6 DESC, 7 DESC, 1 ASC
          LIMIT 1000) AS x -- This outer limit makes testing for opac visibility usably fast
        ' || opac_visibility_join || '
  ORDER BY 3 DESC, 4 DESC NULLS LAST, 5 DESC, 6 DESC, 7 DESC, 1 ASC
  LIMIT $5
'   -- sic, repeat the order by clause in the outer select too
    USING
        query, search_class, headline_opts,
        visibility_org, query_limit, normalization, plain_query
        ;

    -- sort order:
    --  buoyant AND chosen class = match class
    --  chosen field = match field
    --  field weight
    --  rank
    --  buoyancy
    --  value itself

END;
$func$ LANGUAGE PLPGSQL;
