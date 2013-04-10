-- Function: record_entry_aaa_three()
-- Based on part of biblio.indexing_ingest_or_delete()

-- DROP FUNCTION IF EXISTS biblio.record_entry_aaa_three(BIGINT, TEXT);

CREATE OR REPLACE FUNCTION biblio.record_entry_aaa_three(p_id BIGINT, p_marc TEXT)
RETURNS void AS $$
DECLARE
	attr_def        config.record_attr_definition%ROWTYPE;
	attr_value      TEXT;
	xfrm            config.xml_transform%ROWTYPE;
	prev_xfrm       TEXT;
	transformed_xml TEXT;
	normalizer      RECORD;
	new_attrs       HSTORE := ''::HSTORE;
BEGIN			
	FOR attr_def IN SELECT * FROM config.record_attr_definition ORDER BY format LOOP

		IF attr_def.tag IS NOT NULL THEN -- tag (and optional subfield list) selection
			SELECT  ARRAY_TO_STRING(ARRAY_ACCUM(value), COALESCE(attr_def.joiner,' ')) INTO attr_value
			  FROM  (SELECT * FROM metabib.full_rec ORDER BY tag, subfield) AS x
			  WHERE record = p_id
					AND tag LIKE attr_def.tag
					AND CASE
						WHEN attr_def.sf_list IS NOT NULL 
							THEN POSITION(subfield IN attr_def.sf_list) > 0
						ELSE TRUE
						END
			  GROUP BY tag
			  ORDER BY tag
			  LIMIT 1;

		ELSIF attr_def.fixed_field IS NOT NULL THEN -- a named fixed field, see config.marc21_ff_pos_map.fixed_field
			attr_value := biblio.marc21_extract_fixed_field(p_id, attr_def.fixed_field);

		ELSIF attr_def.xpath IS NOT NULL THEN -- and xpath expression

			SELECT INTO xfrm * FROM config.xml_transform WHERE name = attr_def.format;
	
			-- See if we can skip the XSLT ... it's expensive
			IF prev_xfrm IS NULL OR prev_xfrm <> xfrm.name THEN
				-- Can't skip the transform
				IF xfrm.xslt <> '---' THEN
					transformed_xml := oils_xslt_process( p_marc, xfrm.xslt );
				ELSE
					transformed_xml := p_marc;
				END IF;
	
				prev_xfrm := xfrm.name;
			END IF;

			IF xfrm.name IS NULL THEN
				-- just grab the marcxml (empty) transform
				SELECT INTO xfrm * FROM config.xml_transform WHERE xslt = '---' LIMIT 1;
				prev_xfrm := xfrm.name;
			END IF;

			attr_value := oils_xpath_string(attr_def.xpath, transformed_xml, COALESCE(attr_def.joiner,' '), ARRAY[ARRAY[xfrm.prefix, xfrm.namespace_uri]]);

		ELSIF attr_def.phys_char_sf IS NOT NULL THEN -- a named Physical Characteristic, see config.marc21_physical_characteristic_*_map
			SELECT  m.value INTO attr_value
			  FROM  biblio.marc21_physical_characteristics(p_id) v
					JOIN config.marc21_physical_characteristic_value_map m ON (m.id = v.value)
			  WHERE v.subfield = attr_def.phys_char_sf
			  LIMIT 1; -- Just in case ...

		END IF;

		-- apply index normalizers to attr_value
		FOR normalizer IN
			SELECT  n.func AS func,
					n.param_count AS param_count,
					m.params AS params
			  FROM  config.index_normalizer n
					JOIN config.record_attr_index_norm_map m ON (m.norm = n.id)
			  WHERE attr = attr_def.name
			  ORDER BY m.pos 
		LOOP
			EXECUTE 'SELECT ' || normalizer.func || '(' ||
				COALESCE( quote_literal( attr_value ), 'NULL' ) ||
				CASE
					WHEN normalizer.param_count > 0
						THEN ',' || REPLACE( REPLACE( BTRIM(normalizer.params, '[]'), E'\'', E'\\\''), E'"', E'\'') --' help syntax highlighting
						ELSE ''
					END ||
				')' INTO attr_value;
		END LOOP;

		-- Add the new value to the hstore
		new_attrs := new_attrs || hstore( attr_def.name, attr_value );

	END LOOP;
	
	UPDATE metabib.record_attr SET attrs = new_attrs WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;
			