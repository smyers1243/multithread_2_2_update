
--Trigger log_ous_change depends on this function
-- Log each change in oust to oustl, so admins can see what they messed up if someting stops working.
CREATE OR REPLACE FUNCTION ous_change_log() RETURNS TRIGGER AS $ous_change_log$
    DECLARE
    original TEXT;
    BEGIN
        -- Check for which setting is being updated, and log it.
        SELECT INTO original value FROM actor.org_unit_setting WHERE name = NEW.name AND org_unit = NEW.org_unit;
                
        INSERT INTO config.org_unit_setting_type_log (org,original_value,new_value,field_name) VALUES (NEW.org_unit, original, NEW.value, NEW.name);
        
        RETURN NEW;
    END;
$ous_change_log$ LANGUAGE plpgsql;   

--Trigger log_ous_del depends on this function
CREATE OR REPLACE FUNCTION ous_delete_log() RETURNS TRIGGER AS $ous_delete_log$
    DECLARE
    original TEXT;
    BEGIN
        -- Check for which setting is being updated, and log it.
        SELECT INTO original value FROM actor.org_unit_setting WHERE name = OLD.name AND org_unit = OLD.org_unit;
                
        INSERT INTO config.org_unit_setting_type_log (org,original_value,new_value,field_name) VALUES (OLD.org_unit, original, 'null', OLD.name);
        
        RETURN OLD;
    END;
$ous_delete_log$ LANGUAGE plpgsql; 

CREATE OR REPLACE FUNCTION perl_oils_xpath (xpath TEXT, xml TEXT, ns TEXT[][]) RETURNS TEXT[] AS $func$
  use strict;
  use XML::LibXML;

  my $xpath = shift;
  my $doc = shift;
  my $ns_string = shift || '';
  #elog(NOTICE,"ns_string: $ns_string");

  my %ns_list = $ns_string =~ m/\{([^{,]+),([^}]+)\}/g;
  #elog(NOTICE,"NS Prefix $_: URI $ns_list{$_}") for (keys %ns_list);

  # The following approach uses the older XML::LibXML 1.69 / XML::LibXSLT 1.68
  # methods of parsing XML documents and stylesheets, in the hopes of broader
  # compatibility with distributions
  my $parser = eval { $_SHARED{'_xslt_process'}{parsers}{xml} || XML::LibXML->new() };

  #elog(NOTICE, 'got here '. $@);
  return undef if ($@);

  # Cache the XML parser, if we do not already have one
  $_SHARED{'_xslt_process'}{parsers}{xml} = $parser
    unless ($_SHARED{'_xslt_process'}{parsers}{xml});

  # Look for a cached version of the doc, or parse it if none
  my $dom = eval { $_SHARED{'_xslt_process'}{docs}{$doc} || $parser->parse_string($doc) };

  #elog(NOTICE, $@) if $@;
  return undef if ($@);
  #elog(NOTICE, 'got here');

  # Cache the parsed XML doc, if already there
  $_SHARED{'_xslt_process'}{docs}{$doc} = $dom
    unless ($_SHARED{'_xslt_process'}{docs}{$doc});

  # Register the requested namespaces
  $dom->documentElement->setNamespace( $ns_list{$_} => $_ ) for ( keys %ns_list );
  my $xpc = XML::LibXML::XPathContext->new;
  $xpc->registerNs( $ns_list{$_} => $_ ) for ( keys %ns_list );


  # Gather and return nodes
  my @nodes = $dom->findnodes($xpath);
  #elog(NOTICE,"nodes found by $xpath: ". scalar(@nodes));

  return [ map { $_->toStringC14N } @nodes ];
$func$ LANGUAGE PLPERLU;

CREATE OR REPLACE FUNCTION perl_oils_xpath ( TEXT, TEXT ) RETURNS TEXT[] AS $$SELECT perl_oils_xpath( $1, $2, '{}'::TEXT[]);$$ LANGUAGE SQL IMMUTABLE;


-- This is split out because it takes forever to run on large bib collections.
--\qecho ************************************************************************
--\qecho The following transaction, wrapping upgrades 0679 and 0680, may take a
--\qecho *really* long time, and you might be able to run it by itself in
--\qecho parallel with other operations using a separate session.
--\qecho ************************************************************************


CREATE OR REPLACE FUNCTION oils_tsearch2 () RETURNS TRIGGER AS $$
DECLARE
    normalizer      RECORD;
    value           TEXT := '';
BEGIN

    value := NEW.value;

    IF TG_TABLE_NAME::TEXT ~ 'field_entry$' THEN
        FOR normalizer IN
            SELECT  n.func AS func,
                    n.param_count AS param_count,
                    m.params AS params
              FROM  config.index_normalizer n
                    JOIN config.metabib_field_index_norm_map m ON (m.norm = n.id)
              WHERE field = NEW.field AND m.pos < 0
              ORDER BY m.pos LOOP
                EXECUTE 'SELECT ' || normalizer.func || '(' ||
                    quote_literal( value ) ||
                    CASE
                        WHEN normalizer.param_count > 0
                            THEN ',' || REPLACE(REPLACE(BTRIM(normalizer.params,'[]'),E'\'',E'\\\''),E'"',E'\'')
                            ELSE ''
                        END ||
                    ')' INTO value;

        END LOOP;

        NEW.value := value;
    END IF;

    IF NEW.index_vector = ''::tsvector THEN
        RETURN NEW;
    END IF;

    IF TG_TABLE_NAME::TEXT ~ 'field_entry$' THEN
        FOR normalizer IN
            SELECT  n.func AS func,
                    n.param_count AS param_count,
                    m.params AS params
              FROM  config.index_normalizer n
                    JOIN config.metabib_field_index_norm_map m ON (m.norm = n.id)
              WHERE field = NEW.field AND m.pos >= 0
              ORDER BY m.pos LOOP
                EXECUTE 'SELECT ' || normalizer.func || '(' ||
                    quote_literal( value ) ||
                    CASE
                        WHEN normalizer.param_count > 0
                            THEN ',' || REPLACE(REPLACE(BTRIM(normalizer.params,'[]'),E'\'',E'\\\''),E'"',E'\'')
                            ELSE ''
                        END ||
                    ')' INTO value;

        END LOOP;
    END IF;

    IF TG_TABLE_NAME::TEXT ~ 'browse_entry$' THEN
        value :=  ARRAY_TO_STRING(
            evergreen.regexp_split_to_array(value, E'\\W+'), ' '
        );
        value := public.search_normalize(value);
    END IF;

    NEW.index_vector = to_tsvector((TG_ARGV[0])::regconfig, value);

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;



CREATE OR REPLACE FUNCTION serial.materialize_holding_code() RETURNS TRIGGER
AS $func$ 
use strict;

use MARC::Field;
use JSON::XS;

if (not defined $_TD->{new}{holding_code}) {
    elog(WARNING, 'NULL in "holding_code" column of serial.issuance allowed for now, but may not be useful');
    return;
}

# Do nothing if holding_code has not changed...

if ($_TD->{new}{holding_code} eq $_TD->{old}{holding_code}) {
    # ... unless the following internal flag is set.

    my $flag_rv = spi_exec_query(q{
        SELECT * FROM config.internal_flag
        WHERE name = 'serial.rematerialize_on_same_holding_code' AND enabled
    }, 1);
    return unless $flag_rv->{processed};
}


my $holding_code = (new JSON::XS)->decode($_TD->{new}{holding_code});

my $field = new MARC::Field('999', @$holding_code); # tag doesnt matter

my $dstmt = spi_prepare(
    'DELETE FROM serial.materialized_holding_code WHERE issuance = $1',
    'INT'
);
spi_exec_prepared($dstmt, $_TD->{new}{id});

my $istmt = spi_prepare(
    q{
        INSERT INTO serial.materialized_holding_code (
            issuance, subfield, value
        ) VALUES ($1, $2, $3)
    }, qw{INT CHAR TEXT}
);

foreach ($field->subfields) {
    spi_exec_prepared(
        $istmt,
        $_TD->{new}{id},
        $_->[0],
        $_->[1]
    );
}

return;

$func$ LANGUAGE 'plperlu';

-- Create the new 11-parameter function, featuring param_pref_ou
CREATE OR REPLACE FUNCTION search.query_parser_fts (

    param_search_ou INT,
    param_depth     INT,
    param_query     TEXT,
    param_statuses  INT[],
    param_locations INT[],
    param_offset    INT,
    param_check     INT,
    param_limit     INT,
    metarecord      BOOL,
    staff           BOOL,
    param_pref_ou   INT DEFAULT NULL
) RETURNS SETOF search.search_result AS $func$
DECLARE

    current_res         search.search_result%ROWTYPE;
    search_org_list     INT[];
    luri_org_list       INT[];
    tmp_int_list        INT[];

    check_limit         INT;
    core_limit          INT;
    core_offset         INT;
    tmp_int             INT;

    core_result         RECORD;
    core_cursor         REFCURSOR;
    core_rel_query      TEXT;

    total_count         INT := 0;
    check_count         INT := 0;
    deleted_count       INT := 0;
    visible_count       INT := 0;
    excluded_count      INT := 0;

BEGIN

    check_limit := COALESCE( param_check, 1000 );
    core_limit  := COALESCE( param_limit, 25000 );
    core_offset := COALESCE( param_offset, 0 );

    -- core_skip_chk := COALESCE( param_skip_chk, 1 );

    IF param_search_ou > 0 THEN
        IF param_depth IS NOT NULL THEN
            SELECT array_accum(distinct id) INTO search_org_list FROM actor.org_unit_descendants( param_search_ou, param_depth );
        ELSE
            SELECT array_accum(distinct id) INTO search_org_list FROM actor.org_unit_descendants( param_search_ou );
        END IF;

        SELECT array_accum(distinct id) INTO luri_org_list FROM actor.org_unit_ancestors( param_search_ou );

    ELSIF param_search_ou < 0 THEN
        SELECT array_accum(distinct org_unit) INTO search_org_list FROM actor.org_lasso_map WHERE lasso = -param_search_ou;

        FOR tmp_int IN SELECT * FROM UNNEST(search_org_list) LOOP
            SELECT array_accum(distinct id) INTO tmp_int_list FROM actor.org_unit_ancestors( tmp_int );
            luri_org_list := luri_org_list || tmp_int_list;
        END LOOP;

        SELECT array_accum(DISTINCT x.id) INTO luri_org_list FROM UNNEST(luri_org_list) x(id);

    ELSIF param_search_ou = 0 THEN
        -- reserved for user lassos (ou_buckets/type='lasso') with ID passed in depth ... hack? sure.
    END IF;

    IF param_pref_ou IS NOT NULL THEN
        SELECT array_accum(distinct id) INTO tmp_int_list FROM actor.org_unit_ancestors(param_pref_ou);
        luri_org_list := luri_org_list || tmp_int_list;
    END IF;

    OPEN core_cursor FOR EXECUTE param_query;

    LOOP

        FETCH core_cursor INTO core_result;
        EXIT WHEN NOT FOUND;
        EXIT WHEN total_count >= core_limit;

        total_count := total_count + 1;

        CONTINUE WHEN total_count NOT BETWEEN  core_offset + 1 AND check_limit + core_offset;

        check_count := check_count + 1;

        PERFORM 1 FROM biblio.record_entry b WHERE NOT b.deleted AND b.id IN ( SELECT * FROM unnest( core_result.records ) );
        IF NOT FOUND THEN
            -- RAISE NOTICE ' % were all deleted ... ', core_result.records;
            deleted_count := deleted_count + 1;
            CONTINUE;
        END IF;

        PERFORM 1
          FROM  biblio.record_entry b
                JOIN config.bib_source s ON (b.source = s.id)
          WHERE s.transcendant
                AND b.id IN ( SELECT * FROM unnest( core_result.records ) );

        IF FOUND THEN
            -- RAISE NOTICE ' % were all transcendant ... ', core_result.records;
            visible_count := visible_count + 1;

            current_res.id = core_result.id;
            current_res.rel = core_result.rel;

            tmp_int := 1;
            IF metarecord THEN
                SELECT COUNT(DISTINCT s.source) INTO tmp_int FROM metabib.metarecord_source_map s WHERE s.metarecord = core_result.id;
            END IF;

            IF tmp_int = 1 THEN
                current_res.record = core_result.records[1];
            ELSE
                current_res.record = NULL;
            END IF;

            RETURN NEXT current_res;

            CONTINUE;
        END IF;

        PERFORM 1
          FROM  asset.call_number cn
                JOIN asset.uri_call_number_map map ON (map.call_number = cn.id)
                JOIN asset.uri uri ON (map.uri = uri.id)
          WHERE NOT cn.deleted
                AND cn.label = '##URI##'
                AND uri.active
                AND ( param_locations IS NULL OR array_upper(param_locations, 1) IS NULL )
                AND cn.record IN ( SELECT * FROM unnest( core_result.records ) )
                AND cn.owning_lib IN ( SELECT * FROM unnest( luri_org_list ) )
          LIMIT 1;

        IF FOUND THEN
            -- RAISE NOTICE ' % have at least one URI ... ', core_result.records;
            visible_count := visible_count + 1;

            current_res.id = core_result.id;
            current_res.rel = core_result.rel;

            tmp_int := 1;
            IF metarecord THEN
                SELECT COUNT(DISTINCT s.source) INTO tmp_int FROM metabib.metarecord_source_map s WHERE s.metarecord = core_result.id;
            END IF;

            IF tmp_int = 1 THEN
                current_res.record = core_result.records[1];
            ELSE
                current_res.record = NULL;
            END IF;

            RETURN NEXT current_res;

            CONTINUE;
        END IF;

        IF param_statuses IS NOT NULL AND array_upper(param_statuses, 1) > 0 THEN

            PERFORM 1
              FROM  asset.call_number cn
                    JOIN asset.copy cp ON (cp.call_number = cn.id)
              WHERE NOT cn.deleted
                    AND NOT cp.deleted
                    AND cp.status IN ( SELECT * FROM unnest( param_statuses ) )
                    AND cn.record IN ( SELECT * FROM unnest( core_result.records ) )
                    AND cp.circ_lib IN ( SELECT * FROM unnest( search_org_list ) )
              LIMIT 1;

            IF NOT FOUND THEN
                PERFORM 1
                  FROM  biblio.peer_bib_copy_map pr
                        JOIN asset.copy cp ON (cp.id = pr.target_copy)
                  WHERE NOT cp.deleted
                        AND cp.status IN ( SELECT * FROM unnest( param_statuses ) )
                        AND pr.peer_record IN ( SELECT * FROM unnest( core_result.records ) )
                        AND cp.circ_lib IN ( SELECT * FROM unnest( search_org_list ) )
                  LIMIT 1;

                IF NOT FOUND THEN
                -- RAISE NOTICE ' % and multi-home linked records were all status-excluded ... ', core_result.records;
                    excluded_count := excluded_count + 1;
                    CONTINUE;
                END IF;
            END IF;

        END IF;

        IF param_locations IS NOT NULL AND array_upper(param_locations, 1) > 0 THEN

            PERFORM 1
              FROM  asset.call_number cn
                    JOIN asset.copy cp ON (cp.call_number = cn.id)
              WHERE NOT cn.deleted
                    AND NOT cp.deleted
                    AND cp.location IN ( SELECT * FROM unnest( param_locations ) )
                    AND cn.record IN ( SELECT * FROM unnest( core_result.records ) )
                    AND cp.circ_lib IN ( SELECT * FROM unnest( search_org_list ) )
              LIMIT 1;

            IF NOT FOUND THEN
                PERFORM 1
                  FROM  biblio.peer_bib_copy_map pr
                        JOIN asset.copy cp ON (cp.id = pr.target_copy)
                  WHERE NOT cp.deleted
                        AND cp.location IN ( SELECT * FROM unnest( param_locations ) )
                        AND pr.peer_record IN ( SELECT * FROM unnest( core_result.records ) )
                        AND cp.circ_lib IN ( SELECT * FROM unnest( search_org_list ) )
                  LIMIT 1;

                IF NOT FOUND THEN
                    -- RAISE NOTICE ' % and multi-home linked records were all copy_location-excluded ... ', core_result.records;
                    excluded_count := excluded_count + 1;
                    CONTINUE;
                END IF;
            END IF;

        END IF;

        IF staff IS NULL OR NOT staff THEN

            PERFORM 1
              FROM  asset.opac_visible_copies
              WHERE circ_lib IN ( SELECT * FROM unnest( search_org_list ) )
                    AND record IN ( SELECT * FROM unnest( core_result.records ) )
              LIMIT 1;

            IF NOT FOUND THEN
                PERFORM 1
                  FROM  biblio.peer_bib_copy_map pr
                        JOIN asset.opac_visible_copies cp ON (cp.copy_id = pr.target_copy)
                  WHERE cp.circ_lib IN ( SELECT * FROM unnest( search_org_list ) )
                        AND pr.peer_record IN ( SELECT * FROM unnest( core_result.records ) )
                  LIMIT 1;

                IF NOT FOUND THEN

                    -- RAISE NOTICE ' % and multi-home linked records were all visibility-excluded ... ', core_result.records;
                    excluded_count := excluded_count + 1;
                    CONTINUE;
                END IF;
            END IF;

        ELSE

            PERFORM 1
              FROM  asset.call_number cn
                    JOIN asset.copy cp ON (cp.call_number = cn.id)
              WHERE NOT cn.deleted
                    AND NOT cp.deleted
                    AND cp.circ_lib IN ( SELECT * FROM unnest( search_org_list ) )
                    AND cn.record IN ( SELECT * FROM unnest( core_result.records ) )
              LIMIT 1;

            IF NOT FOUND THEN

                PERFORM 1
                  FROM  biblio.peer_bib_copy_map pr
                        JOIN asset.copy cp ON (cp.id = pr.target_copy)
                  WHERE NOT cp.deleted
                        AND cp.circ_lib IN ( SELECT * FROM unnest( search_org_list ) )
                        AND pr.peer_record IN ( SELECT * FROM unnest( core_result.records ) )
                  LIMIT 1;

                IF NOT FOUND THEN

                    PERFORM 1
                      FROM  asset.call_number cn
                            JOIN asset.copy cp ON (cp.call_number = cn.id)
                      WHERE cn.record IN ( SELECT * FROM unnest( core_result.records ) )
                            AND NOT cp.deleted
                      LIMIT 1;

                    IF FOUND THEN
                        -- RAISE NOTICE ' % and multi-home linked records were all visibility-excluded ... ', core_result.records;
                        excluded_count := excluded_count + 1;
                        CONTINUE;
                    END IF;
                END IF;

            END IF;

        END IF;

        visible_count := visible_count + 1;

        current_res.id = core_result.id;
        current_res.rel = core_result.rel;

        tmp_int := 1;
        IF metarecord THEN
            SELECT COUNT(DISTINCT s.source) INTO tmp_int FROM metabib.metarecord_source_map s WHERE s.metarecord = core_result.id;
        END IF;

        IF tmp_int = 1 THEN
            current_res.record = core_result.records[1];
        ELSE
            current_res.record = NULL;
        END IF;

        RETURN NEXT current_res;

        IF visible_count % 1000 = 0 THEN
            -- RAISE NOTICE ' % visible so far ... ', visible_count;
        END IF;

    END LOOP;

    current_res.id = NULL;
    current_res.rel = NULL;
    current_res.record = NULL;
    current_res.total = total_count;
    current_res.checked = check_count;
    current_res.deleted = deleted_count;
    current_res.visible = visible_count;
    current_res.excluded = excluded_count;

    CLOSE core_cursor;

    RETURN NEXT current_res;

END;
$func$ LANGUAGE PLPGSQL;

CREATE INDEX assist_holdings_display
    ON serial.materialized_holding_code (issuance, subfield);

CREATE TRIGGER materialize_holding_code
    AFTER INSERT OR UPDATE ON serial.issuance
    FOR EACH ROW EXECUTE PROCEDURE serial.materialize_holding_code() ;
	
--TODO: Look for could_be_serial_holding_code
-- This throws away data, but only data that causes breakage anyway.
UPDATE serial.issuance SET holding_code = NULL WHERE NOT evergreen.could_be_serial_holding_code(holding_code);