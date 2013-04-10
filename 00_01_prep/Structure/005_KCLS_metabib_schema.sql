DROP INDEX IF EXISTS metabib.normalized_author_field_entry_gist_trgm;
DROP INDEX IF EXISTS metabib.normalized_remove_insignificants_author_field_entry_gist_trgm;

DROP TYPE IF EXISTS metabib.field_entry_template CASCADE;
CREATE TYPE metabib.field_entry_template AS (
        field_class     TEXT,
        field           INT,
        facet_field     BOOL,
        search_field    BOOL,
        browse_field   BOOL,
        source          BIGINT,
        value           TEXT
);

CREATE TABLE metabib.browse_entry (
    id BIGSERIAL PRIMARY KEY,
    value TEXT unique,
    index_vector tsvector
);

CREATE INDEX metabib_browse_entry_index_vector_idx ON metabib.browse_entry USING GIN (index_vector);