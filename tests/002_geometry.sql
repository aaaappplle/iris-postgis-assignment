-- Automated geometry and CRS tests for the IRIS pilot.
-- Run with psql -X -v ON_ERROR_STOP=1 after a completed rebuild.
-- Each file rolls back its transaction so fixture state remains unchanged.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Core geometry types and SRIDs are canonical.
-- ---------------------------------------------------------------------------
\echo '--> Test canonical geometry types and SRID 4326 in iris_core'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM iris_core.parcel
        WHERE GeometryType(geom) <> 'MULTIPOLYGON'
           OR ST_SRID(geom) <> 4326
    ) THEN
        RAISE EXCEPTION
            'Test failed: parcel geometry contract violated';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM iris_core.substation
        WHERE GeometryType(geom) <> 'POINT'
           OR ST_SRID(geom) <> 4326
    ) THEN
        RAISE EXCEPTION
            'Test failed: substation geometry contract violated';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM iris_core.peatland
        WHERE GeometryType(geom) <> 'MULTIPOLYGON'
           OR ST_SRID(geom) <> 4326
    ) THEN
        RAISE EXCEPTION
            'Test failed: peatland geometry contract violated';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM iris_core.screening_layer
        WHERE GeometryType(geom) <> 'MULTIPOLYGON'
           OR ST_SRID(geom) <> 4326
    ) THEN
        RAISE EXCEPTION
            'Test failed: screening-layer geometry contract violated';
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- 2. EPSG:25832 staging geometry was transformed to EPSG:4326.
-- ---------------------------------------------------------------------------
\echo '--> Test SUB-001 transformation from EPSG:25832 to EPSG:4326'
DO $$
DECLARE
    lon DOUBLE PRECISION;
    lat DOUBLE PRECISION;
BEGIN
    SELECT ST_X(geom), ST_Y(geom)
      INTO lon, lat
    FROM iris_core.substation
    WHERE substation_ref = 'SUB-001';

    IF lon IS NULL OR lat IS NULL THEN
        RAISE EXCEPTION
            'Test failed: SUB-001 was not promoted';
    END IF;

    IF lon NOT BETWEEN 10.0 AND 10.03
       OR lat NOT BETWEEN 49.99 AND 50.02 THEN
        RAISE EXCEPTION
            'Test failed: SUB-001 coordinates do not look transformed to EPSG:4326: lon=%, lat=%',
            lon, lat;
    END IF;
END
$$;

-- Discard any test-only changes.
ROLLBACK;

\echo 'All IRIS geometry and CRS tests passed.'
