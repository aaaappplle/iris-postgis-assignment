-- Canonical IRIS core entities.

\echo '--> Create table iris_core.parcel'
CREATE TABLE iris_core.parcel (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code  CHAR(2) NOT NULL,
    region_code   TEXT,
    source_id     TEXT NOT NULL,
    source_date   DATE NOT NULL,
    parcel_ref    TEXT NOT NULL,
    geom          geometry(MultiPolygon, 4326) NOT NULL,
    source_run_id BIGINT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_parcel_business
        UNIQUE (country_code, source_id, parcel_ref),

    CONSTRAINT uq_parcel_country_id
        UNIQUE (country_code, id),

    CONSTRAINT fk_parcel_source_run
        FOREIGN KEY (country_code, source_run_id, source_id, source_date)
        REFERENCES iris_core.source_run (country_code, id, source_id, source_date),

    CONSTRAINT ck_parcel_geom
        CHECK (ST_IsValid(geom) AND NOT ST_IsEmpty(geom))
);

\echo '--> Create table iris_core.substation'
CREATE TABLE iris_core.substation (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code    CHAR(2) NOT NULL,
    region_code     TEXT,
    source_id       TEXT NOT NULL,
    source_date     DATE NOT NULL,
    substation_ref  TEXT NOT NULL,
    name            TEXT,
    geom            geometry(Point, 4326) NOT NULL,
    source_run_id   BIGINT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_substation_business
        UNIQUE (country_code, source_id, substation_ref),

    CONSTRAINT uq_substation_country_id
        UNIQUE (country_code, id),

    CONSTRAINT fk_substation_source_run
        FOREIGN KEY (country_code, source_run_id, source_id, source_date)
        REFERENCES iris_core.source_run (country_code, id, source_id, source_date),

    CONSTRAINT ck_substation_geom
        CHECK (ST_IsValid(geom) AND NOT ST_IsEmpty(geom))
);

\echo '--> Create table iris_core.peatland'
CREATE TABLE iris_core.peatland (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code  CHAR(2) NOT NULL,
    region_code   TEXT,
    source_id     TEXT NOT NULL,
    source_date   DATE NOT NULL,
    peatland_ref  TEXT NOT NULL,
    geom          geometry(MultiPolygon, 4326) NOT NULL,
    source_run_id BIGINT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_peatland_business
        UNIQUE (country_code, source_id, peatland_ref),

    CONSTRAINT uq_peatland_country_id
        UNIQUE (country_code, id),

    CONSTRAINT fk_peatland_source_run
        FOREIGN KEY (country_code, source_run_id, source_id, source_date)
        REFERENCES iris_core.source_run (country_code, id, source_id, source_date),

    CONSTRAINT ck_peatland_geom
        CHECK (ST_IsValid(geom) AND NOT ST_IsEmpty(geom))
);

\echo '--> Create table iris_core.screening_layer'
CREATE TABLE iris_core.screening_layer (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code  CHAR(2) NOT NULL,
    region_code   TEXT,
    source_id     TEXT NOT NULL,
    source_date   DATE NOT NULL,
    layer_ref     TEXT NOT NULL,
    layer_type    TEXT NOT NULL,
    geom          geometry(MultiPolygon, 4326) NOT NULL,
    source_run_id BIGINT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_screening_layer_business
        UNIQUE (country_code, source_id, layer_ref),

    CONSTRAINT uq_screening_layer_country_id
        UNIQUE (country_code, id),

    CONSTRAINT fk_screening_layer_source_run
        FOREIGN KEY (country_code, source_run_id, source_id, source_date)
        REFERENCES iris_core.source_run (country_code, id, source_id, source_date),

    CONSTRAINT ck_screening_layer_geom
        CHECK (ST_IsValid(geom) AND NOT ST_IsEmpty(geom))
);

\echo '--> Create table iris_core.evidence'
CREATE TABLE iris_core.evidence (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code     CHAR(2) NOT NULL,
    parcel_id        BIGINT NOT NULL,
    source_run_id    BIGINT NOT NULL,
    evidence_type    TEXT NOT NULL,
    numeric_value    NUMERIC,
    unit             TEXT,
    text_value       TEXT,
    uncertainty_note TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_evidence_parcel
        FOREIGN KEY (country_code, parcel_id)
        REFERENCES iris_core.parcel (country_code, id),

    CONSTRAINT fk_evidence_source_run
        FOREIGN KEY (country_code, source_run_id)
        REFERENCES iris_core.source_run (country_code, id),

    CONSTRAINT uq_evidence_screening
        UNIQUE (
            country_code,
            parcel_id,
            source_run_id,
            evidence_type,
            text_value
        ),

    CONSTRAINT ck_evidence_has_value
        CHECK (
            numeric_value IS NOT NULL
            OR text_value IS NOT NULL
        ),

    CONSTRAINT ck_evidence_numeric_has_unit
        CHECK (
            numeric_value IS NULL
            OR unit IS NOT NULL
        )
);
