-- Staging tables intentionally keep geometry typing permissive.
-- The source CRS is preserved here and normalized during promotion.

\echo '--> Create table iris_staging.parcel'
CREATE TABLE iris_staging.parcel (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    region_code  TEXT,
    source_id    TEXT NOT NULL,
    source_date  DATE NOT NULL,
    external_id  TEXT NOT NULL,
    geom         geometry NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

\echo '--> Create table iris_staging.substation'
CREATE TABLE iris_staging.substation (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    region_code  TEXT,
    source_id    TEXT NOT NULL,
    source_date  DATE NOT NULL,
    external_id  TEXT NOT NULL,
    name         TEXT,
    geom         geometry NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

\echo '--> Create table iris_staging.peatland'
CREATE TABLE iris_staging.peatland (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    region_code  TEXT,
    source_id    TEXT NOT NULL,
    source_date  DATE NOT NULL,
    external_id  TEXT NOT NULL,
    geom         geometry NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

\echo '--> Create table iris_staging.screening_layer'
CREATE TABLE iris_staging.screening_layer (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    region_code  TEXT,
    source_id    TEXT NOT NULL,
    source_date  DATE NOT NULL,
    external_id  TEXT NOT NULL,
    layer_type   TEXT NOT NULL,
    geom         geometry NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
