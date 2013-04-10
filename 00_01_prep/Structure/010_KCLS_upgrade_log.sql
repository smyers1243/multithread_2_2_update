-- Upgrade Log

CREATE OR REPLACE FUNCTION evergreen.could_be_serial_holding_code(TEXT) RETURNS BOOL AS $$
    use JSON::XS;
    use MARC::Field;

    eval {
        my $holding_code = (new JSON::XS)->decode(shift);
        new MARC::Field('999', @$holding_code);
    };  
    return $@ ? 0 : 1;
$$ LANGUAGE PLPERLU;

-- Drop the old 10-parameter function
DROP FUNCTION IF EXISTS search.query_parser_fts (
    INT, INT, TEXT, INT[], INT[], INT, INT, INT, BOOL, BOOL
);

-- add notify columns to booking.reservation
ALTER TABLE booking.reservation
  ADD COLUMN email_notify BOOLEAN NOT NULL DEFAULT FALSE;
  
  ALTER TABLE container.biblio_record_entry_bucket
    ADD COLUMN description TEXT;

ALTER TABLE container.call_number_bucket
    ADD COLUMN description TEXT;

ALTER TABLE container.copy_bucket
    ADD COLUMN description TEXT;

ALTER TABLE container.user_bucket
    ADD COLUMN description TEXT;



ALTER TABLE acq.lineitem_detail 
    ADD COLUMN receiver	INT REFERENCES actor.usr (id) DEFERRABLE INITIALLY DEFERRED;


-- give lineitems a pointer to their vandelay queued_record

ALTER TABLE acq.lineitem ADD COLUMN queued_record BIGINT
    REFERENCES vandelay.queued_bib_record (id) 
    ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE acq.acq_lineitem_history ADD COLUMN queued_record BIGINT
    REFERENCES vandelay.queued_bib_record (id) 
    ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

-- If we don't do this, we have unprocessed triggers and we can't alter the table
SET CONSTRAINTS serial.issuance_caption_and_pattern_fkey IMMEDIATE;

--Consolidated two statements in an attempt to resolve locked relation error.
ALTER TABLE serial.issuance
    DROP CONSTRAINT IF EXISTS issuance_holding_code_check,
	ADD CHECK (holding_code IS NULL OR could_be_serial_holding_code(holding_code));
--ALTER TABLE serial.issuance ADD CHECK (holding_code IS NULL OR could_be_serial_holding_code(holding_code));

ALTER TABLE serial.distribution
    ADD COLUMN display_grouping TEXT NOT NULL DEFAULT 'chron'
        CHECK (display_grouping IN ('enum', 'chron'));

-- why didn't we just make one summary table in the first place?
CREATE VIEW serial.any_summary AS
    SELECT
        'basic' AS summary_type, id, distribution,
        generated_coverage, textual_holdings, show_generated
    FROM serial.basic_summary
    UNION
    SELECT
        'index' AS summary_type, id, distribution,
        generated_coverage, textual_holdings, show_generated
    FROM serial.index_summary
    UNION
    SELECT
        'supplement' AS summary_type, id, distribution,
        generated_coverage, textual_holdings, show_generated
    FROM serial.supplement_summary ;

CREATE TABLE serial.materialized_holding_code (
    id BIGSERIAL PRIMARY KEY,
    issuance INTEGER NOT NULL REFERENCES serial.issuance (id) ON DELETE CASCADE,
    subfield CHAR,
    value TEXT
);

