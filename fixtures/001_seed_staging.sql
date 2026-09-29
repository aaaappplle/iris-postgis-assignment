BEGIN;

\echo '--> Truncate tables iris_staging.parcel, iris_staging.substation, iris_staging.peatland, iris_staging.screening_layer'
TRUNCATE TABLE
    iris_staging.parcel,
    iris_staging.substation,
    iris_staging.peatland,
    iris_staging.screening_layer
RESTART IDENTITY;

-- PARCEL-001 overlaps PEAT-001 and SCREEN-001.
\echo '--> Insert fixture PARCEL-001 into iris_staging.parcel'
INSERT INTO iris_staging.parcel (
    country_code,
    region_code,
    source_id,
    source_date,
    external_id,
    geom,
    created_at
)
VALUES (
    'DE',
    'TEST-REGION',
    'demo_cadastre',
    DATE '2026-09-01',
    'PARCEL-001',
    ST_GeomFromText(
        'POLYGON((
            10.0000 50.0000,
            10.0100 50.0000,
            10.0100 50.0100,
            10.0000 50.0100,
            10.0000 50.0000
        ))',
        4326
    ),
    TIMESTAMPTZ '2026-09-01 00:00:00+00'
);

-- PARCEL-002 is deliberately away from PEAT-001.
\echo '--> Insert fixture PARCEL-002 into iris_staging.parcel'
INSERT INTO iris_staging.parcel (
    country_code,
    region_code,
    source_id,
    source_date,
    external_id,
    geom,
    created_at
)
VALUES (
    'DE',
    'TEST-REGION',
    'demo_cadastre',
    DATE '2026-09-01',
    'PARCEL-002',
    ST_GeomFromText(
        'POLYGON((
            10.0300 50.0300,
            10.0400 50.0300,
            10.0400 50.0400,
            10.0300 50.0400,
            10.0300 50.0300
        ))',
        4326
    ),
    TIMESTAMPTZ '2026-09-01 00:00:00+00'
);

-- Source geometry intentionally uses EPSG:25832 to demonstrate ST_Transform.
-- These coordinates correspond approximately to lon/lat 10.012, 50.005.
\echo '--> Insert fixture SUB-001 into iris_staging.substation'
INSERT INTO iris_staging.substation (
    country_code,
    region_code,
    source_id,
    source_date,
    external_id,
    name,
    geom,
    created_at
)
VALUES (
    'DE',
    'TEST-REGION',
    'demo_grid_utm32',
    DATE '2026-09-01',
    'SUB-001',
    'Projected CRS Demo Substation',
    ST_SetSRID(
        ST_MakePoint(
            572518.9067892529,
            5539677.2914436925
        ),
        25832
    ),
    TIMESTAMPTZ '2026-09-01 00:00:00+00'
);

\echo '--> Insert fixture PEAT-001 into iris_staging.peatland'
INSERT INTO iris_staging.peatland (
    country_code,
    region_code,
    source_id,
    source_date,
    external_id,
    geom,
    created_at
)
VALUES (
    'DE',
    'TEST-REGION',
    'demo_environment',
    DATE '2026-09-01',
    'PEAT-001',
    ST_GeomFromText(
        'POLYGON((
            10.0050 50.0050,
            10.0150 50.0050,
            10.0150 50.0150,
            10.0050 50.0150,
            10.0050 50.0050
        ))',
        4326
    ),
    TIMESTAMPTZ '2026-09-01 00:00:00+00'
);

\echo '--> Insert fixture SCREEN-001 into iris_staging.screening_layer'
INSERT INTO iris_staging.screening_layer (
    country_code,
    region_code,
    source_id,
    source_date,
    external_id,
    layer_type,
    geom,
    created_at
)
VALUES (
    'DE',
    'TEST-REGION',
    'demo_screening',
    DATE '2026-09-01',
    'SCREEN-001',
    'DEMO_CONSTRAINT',
    ST_GeomFromText(
        'POLYGON((
            9.9980 49.9980,
            10.0040 49.9980,
            10.0040 50.0040,
            9.9980 50.0040,
            9.9980 49.9980
        ))',
        4326
    ),
    TIMESTAMPTZ '2026-09-01 00:00:00+00'
);

COMMIT;
