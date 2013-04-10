-- Function: metabib.reingest_metabib_field_entries_search( bib_id bigint )
-- Only search logic
-- Original Function: metabib.reingest_metabib_field_entries(bigint, boolean, boolean, boolean)

-- DROP FUNCTION metabib.reingest_metabib_field_entries_search(bigint);

CREATE OR REPLACE FUNCTION metabib.reingest_metabib_field_entries_search( bib_id bigint )
RETURNS void AS $BODY$
DECLARE
	fclass		RECORD;
BEGIN

--Modified to only insert publisher records into keyword_field_entry
INSERT INTO metabib.keyword_field_entry (field, source, value) 
	SELECT CASE WHEN field <0 THEN field * -1 else field end AS field, source, value 
	FROM biblio.extract_metabib_field_entry( bib_id ) emfe
	INNER JOIN config.metabib_field mf ON emfe.field = mf.id where mf.name = 'publisher';

END;
$BODY$ LANGUAGE plpgsql VOLATILE;