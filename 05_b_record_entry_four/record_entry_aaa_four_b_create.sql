-- Function: metabib.reingest_metabib_field_entries_browse( bib_id bigint )
-- Only browse logic
-- Original Function: metabib.reingest_metabib_field_entries(bigint, boolean, boolean, boolean)

-- DROP FUNCTION metabib.reingest_metabib_field_entries_browse(bigint);

CREATE OR REPLACE FUNCTION metabib.reingest_metabib_field_entries_browse( bib_id bigint )
RETURNS void AS $BODY$
DECLARE
    ind_data			metabib.field_entry_template%ROWTYPE;
	mbe_row         	metabib.browse_entry%ROWTYPE;
    mbe_id          	BIGINT;
    normalized_value    TEXT;
BEGIN
--	DELETE FROM metabib.browse_entry_def_map WHERE source = bib_id;
	
	FOR ind_data IN SELECT * FROM biblio.extract_metabib_field_entry( bib_id ) LOOP
        IF ind_data.field < 0 THEN
            ind_data.field = -1 * ind_data.field;
        END IF;

        IF ind_data.browse_field THEN
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
--            ELSE
--                INSERT INTO metabib.browse_entry (value) VALUES (normalized_value);
--                mbe_id := CURRVAL('metabib.browse_entry_id_seq'::REGCLASS);
--            END IF;

            INSERT INTO metabib.browse_entry_def_map (entry, def, source)
                VALUES (mbe_id, ind_data.field, ind_data.source);
        END IF;
	END LOOP;
END;
$BODY$ LANGUAGE plpgsql VOLATILE