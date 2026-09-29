-- Automated constraint tests for the IRIS pilot.
-- Run with psql -X -v ON_ERROR_STOP=1 after a completed rebuild.
-- Each file rolls back its transaction so fixture state remains unchanged.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Fixture promotion completed.
-- ---------------------------------------------------------------------------
\echo '--> Test promoted fixture row counts in iris_core'
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM iris_core.parcel) <> 2 THEN
        RAISE EXCEPTION
            'Test failed: expected exactly 2 promoted parcels';
    END IF;

    IF (SELECT COUNT(*) FROM iris_core.substation) <> 1 THEN
        RAISE EXCEPTION
            'Test failed: expected exactly 1 promoted substation';
    END IF;

    IF (SELECT COUNT(*) FROM iris_core.peatland) <> 1 THEN
        RAISE EXCEPTION
            'Test failed: expected exactly 1 promoted peatland';
    END IF;

    IF (SELECT COUNT(*) FROM iris_core.screening_layer) <> 1 THEN
        RAISE EXCEPTION
            'Test failed: expected exactly 1 promoted screening layer';
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- 2. Persisted business entities must have country_code.
-- ---------------------------------------------------------------------------
\echo '--> Test non-null country_code values in iris_core business tables'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM iris_core.parcel WHERE country_code IS NULL
        UNION ALL
        SELECT 1 FROM iris_core.substation WHERE country_code IS NULL
        UNION ALL
        SELECT 1 FROM iris_core.peatland WHERE country_code IS NULL
        UNION ALL
        SELECT 1 FROM iris_core.screening_layer WHERE country_code IS NULL
    ) THEN
        RAISE EXCEPTION
            'Test failed: core business entity has NULL country_code';
    END IF;
END
$$;

-- Also prove the staging NOT NULL constraint rejects an invalid record.
\echo '--> Test iris_staging.parcel rejects a null country_code'
DO $$
BEGIN
    BEGIN
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
            NULL,
            'TEST-REGION',
            'test_invalid_country',
            DATE '2026-09-01',
            'INVALID-COUNTRY',
            ST_GeomFromText(
                'POLYGON((10 50, 10.001 50, 10.001 50.001, 10 50.001, 10 50))',
                4326
            ),
            TIMESTAMPTZ '2026-09-01 00:00:00+00'
        );

        RAISE EXCEPTION
            'Test failed: staging accepted NULL country_code';
    EXCEPTION
        WHEN not_null_violation THEN
            NULL;
    END;
END
$$;

-- ---------------------------------------------------------------------------
-- 3. Country-scoped business uniqueness rejects a duplicate in the same country.
-- ---------------------------------------------------------------------------
\echo '--> Test duplicate parcel identity is rejected within one country'
DO $$
DECLARE
    de_source_run BIGINT;
BEGIN
    SELECT id
      INTO de_source_run
    FROM iris_core.source_run
    WHERE country_code = 'DE'
      AND source_id = 'demo_cadastre'
      AND source_date = DATE '2026-09-01';

    BEGIN
        INSERT INTO iris_core.parcel (
            country_code,
            region_code,
            source_id,
            source_date,
            parcel_ref,
            geom,
            source_run_id,
            created_at
        )
        VALUES (
            'DE',
            'TEST-REGION',
            'demo_cadastre',
            DATE '2026-09-01',
            'PARCEL-001',
            ST_Multi(
                ST_GeomFromText(
                    'POLYGON((11 51, 11.001 51, 11.001 51.001, 11 51.001, 11 51))',
                    4326
                )
            )::geometry(MultiPolygon, 4326),
            de_source_run,
            CURRENT_TIMESTAMP
        );

        RAISE EXCEPTION
            'Test failed: duplicate country-scoped parcel business key was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            NULL;
    END;
END
$$;

-- ---------------------------------------------------------------------------
-- 4. The same business identifier is allowed in another country.
-- ---------------------------------------------------------------------------
\echo '--> Test the same parcel identity is allowed in another country'
DO $$
DECLARE
    fr_source_run BIGINT;
BEGIN
    INSERT INTO iris_core.source_run (
        country_code,
        source_id,
        source_date
    )
    VALUES (
        'FR',
        'demo_cadastre',
        DATE '2026-09-01'
    )
    RETURNING id INTO fr_source_run;

    INSERT INTO iris_core.parcel (
        country_code,
        region_code,
        source_id,
        source_date,
        parcel_ref,
        geom,
        source_run_id
    )
    VALUES (
        'FR',
        'TEST-REGION',
        'demo_cadastre',
        DATE '2026-09-01',
        'PARCEL-001',
        ST_Multi(
            ST_GeomFromText(
                'POLYGON((2.35 48.85, 2.351 48.85, 2.351 48.851, 2.35 48.851, 2.35 48.85))',
                4326
            )
        )::geometry(MultiPolygon, 4326),
        fr_source_run
    );

    IF NOT EXISTS (
        SELECT 1
        FROM iris_core.parcel
        WHERE country_code = 'FR'
          AND source_id = 'demo_cadastre'
          AND parcel_ref = 'PARCEL-001'
    ) THEN
        RAISE EXCEPTION
            'Test failed: same business identifier was not allowed in a different country';
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- 5. Country-scoped FK rejects a cross-country relationship.
-- ---------------------------------------------------------------------------
\echo '--> Test cross-country parcel provenance is rejected'
DO $$
DECLARE
    fr_source_run BIGINT;
BEGIN
    SELECT id
      INTO fr_source_run
    FROM iris_core.source_run
    WHERE country_code = 'FR'
      AND source_id = 'demo_cadastre'
      AND source_date = DATE '2026-09-01';

    BEGIN
        INSERT INTO iris_core.parcel (
            country_code,
            region_code,
            source_id,
            source_date,
            parcel_ref,
            geom,
            source_run_id
        )
        VALUES (
            'DE',
            'TEST-REGION',
            'test_cross_country',
            DATE '2026-09-01',
            'CROSS-COUNTRY-001',
            ST_Multi(
                ST_GeomFromText(
                    'POLYGON((10.1 50.1, 10.101 50.1, 10.101 50.101, 10.1 50.101, 10.1 50.1))',
                    4326
                )
            )::geometry(MultiPolygon, 4326),
            fr_source_run
        );

        RAISE EXCEPTION
            'Test failed: cross-country source_run reference was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            NULL;
    END;
END
$$;

-- Discard any test-only changes.
ROLLBACK;

\echo 'All IRIS constraint tests passed.'
