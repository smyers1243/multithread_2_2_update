-- Function: metabib.reingest_metabib_field_entries_facet( bib_id bigint )
-- Only facet logic
-- Original Function: metabib.reingest_metabib_field_entries(bigint, boolean, boolean, boolean)

-- DROP FUNCTION metabib.reingest_metabib_field_entries_facet(bigint);

CREATE OR REPLACE FUNCTION metabib.reingest_metabib_field_entries_facet( bib_id bigint )
RETURNS void AS $BODY$
DECLARE
    ind_data	metabib.field_entry_template%ROWTYPE;
BEGIN
	DELETE FROM metabib.facet_entry WHERE source = bib_id;
	
	FOR ind_data IN SELECT * FROM biblio.extract_metabib_field_entry( bib_id ) LOOP
        IF ind_data.field < 0 THEN
            ind_data.field = -1 * ind_data.field;
        END IF;

        IF ind_data.facet_field THEN
            INSERT INTO metabib.facet_entry (field, source, value)
                VALUES (ind_data.field, ind_data.source, ind_data.value);
        END IF;
	END LOOP;
END;
$BODY$ LANGUAGE plpgsql VOLATILE