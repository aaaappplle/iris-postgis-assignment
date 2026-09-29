-- Minimal ingestion/provenance metadata for the pilot.
--
-- Pilot simplification:
-- (country_code, source_id, source_date) is treated as one logical source run.
-- A production design could use an independent run UUID/token and allow multiple
-- ingestion attempts for the same source/date.

\echo '--> Create table iris_core.source_run'
CREATE TABLE iris_core.source_run (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    source_id    TEXT NOT NULL,
    source_date  DATE NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_source_run_business
        UNIQUE (country_code, source_id, source_date),

    -- Required as a composite FK target for country-scoped references.
    CONSTRAINT uq_source_run_country_id
        UNIQUE (country_code, id),

    CONSTRAINT uq_source_run_provenance
        UNIQUE (country_code, id, source_id, source_date)
);
