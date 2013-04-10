-- Create evergreen.rank_cp_status(int)
CREATE TYPE evergreen.patch AS (patch TEXT);

CREATE OR REPLACE FUNCTION evergreen.rank_cp_status(status INT)
RETURNS INTEGER AS $$
    WITH totally_available AS (
        SELECT id, 0 AS avail_rank
        FROM config.copy_status
        WHERE opac_visible IS TRUE
            AND copy_active IS TRUE
            AND id != 1 -- "Checked out"
    ), almost_available AS (
        SELECT id, 10 AS avail_rank
        FROM config.copy_status
        WHERE holdable IS TRUE
            AND opac_visible IS TRUE
            AND copy_active IS FALSE
            OR id = 1 -- "Checked out"
    )
    SELECT COALESCE(
        (SELECT avail_rank FROM totally_available WHERE $1 IN (id)),
        (SELECT avail_rank FROM almost_available WHERE $1 IN (id)),
        100
    );
$$ LANGUAGE SQL STABLE;

DROP FUNCTION IF EXISTS evergreen.array_overlap_check(/* field */);
CREATE OR REPLACE FUNCTION evergreen.array_overlap_check (/* field */) RETURNS TRIGGER AS $$
DECLARE
    fld     TEXT;
    cnt     INT;
BEGIN
    fld := TG_ARGV[1];
    EXECUTE 'SELECT COUNT(*) FROM '|| TG_TABLE_SCHEMA ||'.'|| TG_TABLE_NAME ||' WHERE '|| fld ||' && ($1).'|| fld INTO cnt USING NEW;
    IF cnt > 0 THEN
        RAISE EXCEPTION 'Cannot insert duplicate array into field % of table %', fld, TG_TABLE_SCHEMA ||'.'|| TG_TABLE_NAME;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_deprecates(TEXT);
DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_supersedes(TEXT);

DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_deprecates ( my_db_patch TEXT );
-- List applied db patches that are deprecated by (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_deprecates ( my_db_patch TEXT ) RETURNS SETOF evergreen.patch AS $$
    SELECT  DISTINCT l.version
      FROM  config.upgrade_log l
            JOIN config.db_patch_dependencies d ON (l.version::TEXT[] && d.deprecates)
      WHERE d.db_patch = $1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.regexp_split_to_array(TEXT, TEXT);
-- The advantage of this over the stock regexp_split_to_array() is that it
-- won't degrade unicode strings.
CREATE OR REPLACE FUNCTION evergreen.regexp_split_to_array(TEXT, TEXT)
RETURNS TEXT[] AS $$
    return encode_array_literal([split $_[1], $_[0]]);
$$ LANGUAGE PLPERLU STRICT IMMUTABLE;

DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_supersedes ( my_db_patch TEXT );
-- List applied db patches that are superseded by (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_supersedes ( my_db_patch TEXT ) RETURNS SETOF evergreen.patch AS $$
    SELECT  DISTINCT l.version
      FROM  config.upgrade_log l
            JOIN config.db_patch_dependencies d ON (l.version::TEXT[] && d.supersedes)
      WHERE d.db_patch = $1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_deprecated ( my_db_patch TEXT );
-- List applied db patches that deprecates (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_deprecated ( my_db_patch TEXT ) RETURNS TEXT AS $$
    SELECT  db_patch
      FROM  config.db_patch_dependencies
      WHERE ARRAY[$1]::TEXT[] && deprecates
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_superseded ( my_db_patch TEXT );
-- List applied db patches that supersedes (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_superseded ( my_db_patch TEXT ) RETURNS TEXT AS $$
    SELECT  db_patch
      FROM  config.db_patch_dependencies
      WHERE ARRAY[$1]::TEXT[] && supersedes
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_verify_no_dep_conflicts ( my_db_patch TEXT );
-- Make sure that no deprecated or superseded db patches are currently applied
CREATE OR REPLACE FUNCTION evergreen.upgrade_verify_no_dep_conflicts ( my_db_patch TEXT ) RETURNS BOOL AS $$
    SELECT  COUNT(*) = 0
      FROM  (SELECT * FROM evergreen.upgrade_list_applied_deprecates( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_supersedes( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_deprecated( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_superseded( $1 ))x
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_deps_block_check ( my_db_patch TEXT, my_applied_to TEXT );
-- Raise an exception if there are, in fact, dep/sup confilct
CREATE OR REPLACE FUNCTION evergreen.upgrade_deps_block_check ( my_db_patch TEXT, my_applied_to TEXT ) RETURNS BOOL AS $$
DECLARE 
    deprecates TEXT;
    supersedes TEXT;
BEGIN
    IF NOT evergreen.upgrade_verify_no_dep_conflicts( my_db_patch ) THEN
        SELECT  STRING_AGG(patch, ', ') INTO deprecates FROM evergreen.upgrade_list_applied_deprecates(my_db_patch);
        SELECT  STRING_AGG(patch, ', ') INTO supersedes FROM evergreen.upgrade_list_applied_supersedes(my_db_patch);
        RAISE EXCEPTION '
Upgrade script % can not be applied:
  applied deprecated scripts %
  applied superseded scripts %
  deprecated by %
  superseded by %',
            my_db_patch,
            ARRAY_AGG(evergreen.upgrade_list_applied_deprecates(my_db_patch)),
            ARRAY_AGG(evergreen.upgrade_list_applied_supersedes(my_db_patch)),
            evergreen.upgrade_list_applied_deprecated(my_db_patch),
            evergreen.upgrade_list_applied_superseded(my_db_patch);
    END IF;

    INSERT INTO config.upgrade_log (version, applied_to) VALUES (my_db_patch, my_applied_to);
    RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;

-- Evergreen DB patch 0536.schema.lazy_circ-barcode_lookup.sql
--
DROP FUNCTION evergreen.upgrade_deps_block_check(text,text);
DROP FUNCTION evergreen.upgrade_verify_no_dep_conflicts(text);
DROP FUNCTION evergreen.upgrade_list_applied_deprecated(text);
DROP FUNCTION evergreen.upgrade_list_applied_superseded(text);

CREATE TYPE evergreen.barcode_set AS (type TEXT, id BIGINT, barcode TEXT);

DROP FUNCTION IF EXISTS evergreen.get_barcodes(select_ou INT, type TEXT, in_barcode TEXT);
CREATE OR REPLACE FUNCTION evergreen.get_barcodes(select_ou INT, type TEXT, in_barcode TEXT) RETURNS SETOF evergreen.barcode_set AS $$
DECLARE
    cur_barcode TEXT;
    barcode_len INT;
    completion_len  INT;
    asset_barcodes  TEXT[];
    actor_barcodes  TEXT[];
    do_asset    BOOL = false;
    do_serial   BOOL = false;
    do_booking  BOOL = false;
    do_actor    BOOL = false;
    completion_set  config.barcode_completion%ROWTYPE;
BEGIN

    IF position('asset' in type) > 0 THEN
        do_asset = true;
    END IF;
    IF position('serial' in type) > 0 THEN
        do_serial = true;
    END IF;
    IF position('booking' in type) > 0 THEN
        do_booking = true;
    END IF;
    IF do_asset OR do_serial OR do_booking THEN
        asset_barcodes = asset_barcodes || in_barcode;
    END IF;
    IF position('actor' in type) > 0 THEN
        do_actor = true;
        actor_barcodes = actor_barcodes || in_barcode;
    END IF;

    barcode_len := length(in_barcode);

    FOR completion_set IN
      SELECT * FROM config.barcode_completion
        WHERE active
        AND org_unit IN (SELECT aou.id FROM actor.org_unit_ancestors(select_ou) aou)
        LOOP
        IF completion_set.prefix IS NULL THEN
            completion_set.prefix := '';
        END IF;
        IF completion_set.suffix IS NULL THEN
            completion_set.suffix := '';
        END IF;
        IF completion_set.length = 0 OR completion_set.padding IS NULL OR length(completion_set.padding) = 0 THEN
            cur_barcode = completion_set.prefix || in_barcode || completion_set.suffix;
        ELSE
            completion_len = completion_set.length - length(completion_set.prefix) - length(completion_set.suffix);
            IF completion_len >= barcode_len THEN
                IF completion_set.padding_end THEN
                    cur_barcode = rpad(in_barcode, completion_len, completion_set.padding);
                ELSE
                    cur_barcode = lpad(in_barcode, completion_len, completion_set.padding);
                END IF;
                cur_barcode = completion_set.prefix || cur_barcode || completion_set.suffix;
            END IF;
        END IF;
        IF completion_set.actor THEN
            actor_barcodes = actor_barcodes || cur_barcode;
        END IF;
        IF completion_set.asset THEN
            asset_barcodes = asset_barcodes || cur_barcode;
        END IF;
    END LOOP;

    IF do_asset AND do_serial THEN
        RETURN QUERY SELECT 'asset'::TEXT, id, barcode FROM ONLY asset.copy WHERE barcode = ANY(asset_barcodes) AND deleted = false;
        RETURN QUERY SELECT 'serial'::TEXT, id, barcode FROM serial.unit WHERE barcode = ANY(asset_barcodes) AND deleted = false;
    ELSIF do_asset THEN
        RETURN QUERY SELECT 'asset'::TEXT, id, barcode FROM asset.copy WHERE barcode = ANY(asset_barcodes) AND deleted = false;
    ELSIF do_serial THEN
        RETURN QUERY SELECT 'serial'::TEXT, id, barcode FROM serial.unit WHERE barcode = ANY(asset_barcodes) AND deleted = false;
    END IF;
    IF do_booking THEN
        RETURN QUERY SELECT 'booking'::TEXT, id::BIGINT, barcode FROM booking.resource WHERE barcode = ANY(asset_barcodes);
    END IF;
    IF do_actor THEN
        RETURN QUERY SELECT 'actor'::TEXT, c.usr::BIGINT, c.barcode FROM actor.card c JOIN actor.usr u ON c.usr = u.id WHERE c.barcode = ANY(actor_barcodes) AND c.active AND NOT u.deleted ORDER BY usr;
    END IF;
    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION evergreen.get_barcodes(INT, TEXT, TEXT) IS $$
Given user input, find an appropriate barcode in the proper class.

Will add prefix/suffix information to do so, and return all results.
$$;

DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_deprecated ( my_db_patch TEXT );
-- List applied db patches that deprecates (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_deprecated ( my_db_patch TEXT ) RETURNS SETOF TEXT AS $$
    SELECT  db_patch
      FROM  config.db_patch_dependencies
      WHERE ARRAY[$1]::TEXT[] && deprecates
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_superseded ( my_db_patch TEXT );
-- List applied db patches that supersedes (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_superseded ( my_db_patch TEXT ) RETURNS SETOF TEXT AS $$
    SELECT  db_patch
      FROM  config.db_patch_dependencies
      WHERE ARRAY[$1]::TEXT[] && supersedes
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_verify_no_dep_conflicts ( my_db_patch TEXT );
-- Make sure that no deprecated or superseded db patches are currently applied
CREATE OR REPLACE FUNCTION evergreen.upgrade_verify_no_dep_conflicts ( my_db_patch TEXT ) RETURNS BOOL AS $$
    SELECT  COUNT(*) = 0
      FROM  (SELECT * FROM evergreen.upgrade_list_applied_deprecates( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_supersedes( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_deprecated( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_superseded( $1 ))x
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_deps_block_check ( my_db_patch TEXT, my_applied_to TEXT );
-- Raise an exception if there are, in fact, dep/sup confilct
CREATE OR REPLACE FUNCTION evergreen.upgrade_deps_block_check ( my_db_patch TEXT, my_applied_to TEXT ) RETURNS BOOL AS $$
BEGIN
    IF NOT evergreen.upgrade_verify_no_dep_conflicts( my_db_patch ) THEN
        RAISE EXCEPTION '
Upgrade script % can not be applied:
  applied deprecated scripts %
  applied superseded scripts %
  deprecated by %
  superseded by %',
            my_db_patch,
            ARRAY_ACCUM(evergreen.upgrade_list_applied_deprecates(my_db_patch)),
            ARRAY_ACCUM(evergreen.upgrade_list_applied_supersedes(my_db_patch)),
            evergreen.upgrade_list_applied_deprecated(my_db_patch),
            evergreen.upgrade_list_applied_superseded(my_db_patch);
    END IF;

    INSERT INTO config.upgrade_log (version, applied_to) VALUES (my_db_patch, my_applied_to);
    RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS evergreen.array_remove_item_by_value(inp ANYARRAY, el ANYELEMENT);
CREATE OR REPLACE FUNCTION evergreen.array_remove_item_by_value(inp ANYARRAY, el ANYELEMENT) RETURNS anyarray AS $$ SELECT ARRAY_ACCUM(x.e) FROM UNNEST( $1 ) x(e) WHERE x.e <> $2; $$ LANGUAGE SQL STABLE;

-- evergreen.generic_map_normalizer 
DROP FUNCTION IF EXISTS evergreen.generic_map_normalizer ( TEXT, TEXT );
CREATE OR REPLACE FUNCTION evergreen.generic_map_normalizer ( TEXT, TEXT ) RETURNS TEXT AS $f$
my $string = shift;
my %map;

my $default = $string;

$_ = shift;
while (/^\s*?(.*?)\s*?=>\s*?(\S+)\s*/) {
    if ($1 eq '') {
        $default = $2;
    } else {
        $map{$2} = [split(/\s*,\s*/, $1)];
    }
    $_ = $';	
}

for my $key ( keys %map ) {
    return $key if (grep { $_ eq $string } @{ $map{$key} });
}

return $default;

$f$ LANGUAGE PLPERLU;
--'
DROP FUNCTION IF EXISTS evergreen.org_top();
CREATE OR REPLACE FUNCTION evergreen.org_top() RETURNS SETOF actor.org_unit AS $$ SELECT * FROM actor.org_unit WHERE parent_ou IS NULL LIMIT 1; $$ LANGUAGE SQL STABLE ROWS 1;

-- create the normalizer
DROP FUNCTION IF EXISTS evergreen.coded_value_map_normalizer( input TEXT, ctype TEXT );
CREATE OR REPLACE FUNCTION evergreen.coded_value_map_normalizer( input TEXT, ctype TEXT ) 
    RETURNS TEXT AS $F$
        SELECT COALESCE(value,$1) 
            FROM config.coded_value_map 
            WHERE ctype = $2 AND code = $1;
$F$ LANGUAGE SQL;

-- Temp function for migrating circ mod limits.
DROP FUNCTION IF EXISTS evergreen.temp_migrate_circ_mod_limits();
CREATE OR REPLACE FUNCTION evergreen.temp_migrate_circ_mod_limits() RETURNS VOID AS $func$
DECLARE
    circ_mod_group config.circ_matrix_circ_mod_test%ROWTYPE;
    current_set INT;
    circ_mod_count INT;
BEGIN
    FOR circ_mod_group IN SELECT * FROM config.circ_matrix_circ_mod_test LOOP
        INSERT INTO config.circ_limit_set(name, owning_lib, items_out, depth, global, description)
            SELECT org_unit || ' : Matchpoint ' || circ_mod_group.matchpoint || ' : Circ Mod Test ' || circ_mod_group.id, org_unit, circ_mod_group.items_out, 0, false, 'Migrated from Circ Mod Test System'
                FROM config.circ_matrix_matchpoint WHERE id = circ_mod_group.matchpoint
            RETURNING id INTO current_set;
        INSERT INTO config.circ_matrix_limit_set_map(matchpoint, limit_set, fallthrough, active) VALUES (circ_mod_group.matchpoint, current_set, false, true);
        INSERT INTO config.circ_limit_set_circ_mod_map(limit_set, circ_mod)
            SELECT current_set, circ_mod FROM config.circ_matrix_circ_mod_test_map WHERE circ_mod_test = circ_mod_group.id;
        SELECT INTO circ_mod_count count(id) FROM config.circ_limit_set_circ_mod_map WHERE limit_set = current_set;
        RAISE NOTICE 'Created limit set with id % and % circ modifiers attached to matchpoint %', current_set, circ_mod_count, circ_mod_group.matchpoint;
    END LOOP;
END;
$func$ LANGUAGE plpgsql;

--EXECUTE TEMP FUNCTION.  Test run indicates 2.285ms
SELECT * FROM evergreen.temp_migrate_circ_mod_limits();

-- Drop the temp function
DROP FUNCTION IF EXISTS evergreen.temp_migrate_circ_mod_limits();
DROP FUNCTION IF EXISTS evergreen.temp_migrate_circ_mod_limits();

DROP FUNCTION IF EXISTS evergreen.rank_ou(lib INT, search_lib INT, pref_lib INT);
CREATE OR REPLACE FUNCTION evergreen.rank_ou(lib INT, search_lib INT, pref_lib INT DEFAULT NULL)
RETURNS INTEGER AS $$
    WITH search_libs AS (
        SELECT id, distance FROM actor.org_unit_descendants_distance($2)
    )
    SELECT COALESCE(
        (SELECT -10000 FROM actor.org_unit
         WHERE $1 = $3 AND id = $3 AND $2 IN (
                SELECT id FROM actor.org_unit WHERE parent_ou IS NULL
             )
        ),
        (SELECT distance FROM search_libs WHERE id = $1),
        10000
    );
$$ LANGUAGE SQL STABLE;

DROP FUNCTION IF EXISTS evergreen.ranked_volumes(
    bibid BIGINT, 
    ouid INT,
    depth INT,
    slimit HSTORE,
    soffset HSTORE,
    pref_lib INT
);
CREATE OR REPLACE FUNCTION evergreen.ranked_volumes(
    bibid BIGINT, 
    ouid INT,
    depth INT DEFAULT NULL,
    slimit HSTORE DEFAULT NULL,
    soffset HSTORE DEFAULT NULL,
    pref_lib INT DEFAULT NULL
) RETURNS TABLE (id BIGINT, name TEXT, label_sortkey TEXT, rank BIGINT) AS $$
    SELECT ua.id, ua.name, ua.label_sortkey, MIN(ua.rank) AS rank FROM (
        SELECT acn.id, aou.name, acn.label_sortkey,
            evergreen.rank_ou(aou.id, $2, $6), evergreen.rank_cp_status(acp.status),
            RANK() OVER w
        FROM asset.call_number acn
            JOIN asset.copy acp ON (acn.id = acp.call_number)
            JOIN actor.org_unit_descendants( $2, COALESCE(
                $3, (
                    SELECT depth
                    FROM actor.org_unit_type aout
                        INNER JOIN actor.org_unit ou ON ou_type = aout.id
                    WHERE ou.id = $2
                ), $6)
            ) AS aou ON (acp.circ_lib = aou.id)
        WHERE acn.record = $1
            AND acn.deleted IS FALSE
            AND acp.deleted IS FALSE
        GROUP BY acn.id, acp.status, aou.name, acn.label_sortkey, aou.id
        WINDOW w AS (
            ORDER BY evergreen.rank_ou(aou.id, $2, $6), evergreen.rank_cp_status(acp.status)
        )
    ) AS ua
    GROUP BY ua.id, ua.name, ua.label_sortkey
    ORDER BY rank, ua.name, ua.label_sortkey
    LIMIT ($4 -> 'acn')::INT
    OFFSET ($5 -> 'acn')::INT;
$$
LANGUAGE SQL STABLE;

DROP FUNCTION IF EXISTS evergreen.located_uris (
    bibid BIGINT, 
    ouid INT,
    pref_lib INT
);
CREATE OR REPLACE FUNCTION evergreen.located_uris (
    bibid BIGINT, 
    ouid INT,
    pref_lib INT DEFAULT NULL
) RETURNS TABLE (id BIGINT, name TEXT, label_sortkey TEXT, rank INT) AS $$
    SELECT acn.id, aou.name, acn.label_sortkey, evergreen.rank_ou(aou.id, $2, $3) AS pref_ou
      FROM asset.call_number acn
           INNER JOIN asset.uri_call_number_map auricnm ON acn.id = auricnm.call_number 
           INNER JOIN asset.uri auri ON auri.id = auricnm.uri
           INNER JOIN actor.org_unit_ancestors( COALESCE($3, $2) ) aou ON (acn.owning_lib = aou.id)
      WHERE acn.record = $1
          AND acn.deleted IS FALSE
          AND auri.active IS TRUE
    UNION
    SELECT acn.id, aou.name, acn.label_sortkey, evergreen.rank_ou(aou.id, $2, $3) AS pref_ou
      FROM asset.call_number acn
           INNER JOIN asset.uri_call_number_map auricnm ON acn.id = auricnm.call_number 
           INNER JOIN asset.uri auri ON auri.id = auricnm.uri
           INNER JOIN actor.org_unit_ancestors( $2 ) aou ON (acn.owning_lib = aou.id)
      WHERE acn.record = $1
          AND acn.deleted IS FALSE
          AND auri.active IS TRUE;
$$
LANGUAGE SQL STABLE;

DROP FUNCTION IF EXISTS evergreen.could_be_serial_holding_code(TEXT);
CREATE OR REPLACE FUNCTION evergreen.could_be_serial_holding_code(TEXT) RETURNS BOOL AS $$
    use JSON::XS;
    use MARC::Field;

    eval {
        my $holding_code = (new JSON::XS)->decode(shift);
        new MARC::Field('999', @$holding_code);
    };  
    return $@ ? 0 : 1;
$$ LANGUAGE PLPERLU;

--Added 2/11/2013
-- DROP FUNCTION get_locale_name(text);

CREATE OR REPLACE FUNCTION get_locale_name(IN locale text, OUT name text, OUT description text)
  RETURNS record AS
$BODY$
DECLARE
    eg_locale TEXT;
BEGIN
    eg_locale := LOWER(SUBSTRING(locale FROM 1 FOR 2)) || '-' || UPPER(SUBSTRING(locale FROM 4 FOR 2));
        
    SELECT i18nc.string INTO name
    FROM config.i18n_locale i18nl
       INNER JOIN config.i18n_core i18nc ON i18nl.code = i18nc.translation
    WHERE i18nc.identity_value = eg_locale
       AND code = eg_locale
       AND i18nc.fq_field = 'i18n_l.name';

    IF name IS NULL THEN
       SELECT i18nl.name INTO name
       FROM config.i18n_locale i18nl
       WHERE code = eg_locale;
    END IF;

    SELECT i18nc.string INTO description
    FROM config.i18n_locale i18nl
       INNER JOIN config.i18n_core i18nc ON i18nl.code = i18nc.translation
    WHERE i18nc.identity_value = eg_locale
       AND code = eg_locale
       AND i18nc.fq_field = 'i18n_l.description';

    IF description IS NULL THEN
       SELECT i18nl.description INTO description
       FROM config.i18n_locale i18nl
       WHERE code = eg_locale;
    END IF;
END;
$BODY$
  LANGUAGE plpgsql STABLE
  COST 1;
ALTER FUNCTION get_locale_name(text)
  OWNER TO evergreen;

