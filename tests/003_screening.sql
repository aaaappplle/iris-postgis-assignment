-- Automated spatial screening and evidence tests for the IRIS pilot.
-- Run with psql -X -v ON_ERROR_STOP=1 after a completed rebuild.
-- Each file rolls back its transaction so fixture state remains unchanged.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Expected peatland spatial behavior.
-- ---------------------------------------------------------------------------
\echo '--> Test parcel and peatland intersection fixtures'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM iris_core.parcel AS p
        JOIN iris_core.peatland AS pt
          ON p.country_code = pt.country_code
        WHERE p.parcel_ref = 'PARCEL-001'
          AND pt.peatland_ref = 'PEAT-001'
          AND ST_Intersects(p.geom, pt.geom)
    ) THEN
        RAISE EXCEPTION
            'Test failed: PARCEL-001 should intersect PEAT-001';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM iris_core.parcel AS p
        JOIN iris_core.peatland AS pt
          ON p.country_code = pt.country_code
        WHERE p.parcel_ref = 'PARCEL-002'
          AND pt.peatland_ref = 'PEAT-001'
          AND ST_Intersects(p.geom, pt.geom)
    ) THEN
        RAISE EXCEPTION
            'Test failed: PARCEL-002 should not intersect PEAT-001';
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- 2. Expected screening-layer spatial behavior.
-- ---------------------------------------------------------------------------
\echo '--> Test parcel and screening-layer intersection fixtures'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM iris_core.parcel AS p
        JOIN iris_core.screening_layer AS sl
          ON p.country_code = sl.country_code
        WHERE p.parcel_ref = 'PARCEL-001'
          AND sl.layer_ref = 'SCREEN-001'
          AND ST_Intersects(p.geom, sl.geom)
    ) THEN
        RAISE EXCEPTION
            'Test failed: PARCEL-001 should intersect SCREEN-001';
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- 3. Expected substation proximity.
-- ---------------------------------------------------------------------------
\echo '--> Test parcel and substation proximity within 500 m'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM iris_core.parcel AS p
        JOIN iris_core.substation AS s
          ON p.country_code = s.country_code
        WHERE p.parcel_ref = 'PARCEL-001'
          AND s.substation_ref = 'SUB-001'
          AND ST_DWithin(
                p.geom::geography,
                s.geom::geography,
                500
              )
    ) THEN
        RAISE EXCEPTION
            'Test failed: PARCEL-001 should be within 500 m of SUB-001';
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- 4. Expected persisted screening evidence.
-- ---------------------------------------------------------------------------
\echo '--> Test the three persisted iris_core.evidence rows and provenance'
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM iris_core.evidence) <> 3 THEN
        RAISE EXCEPTION
            'Test failed: expected exactly 3 screening evidence rows';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM iris_core.evidence AS e
        JOIN iris_core.parcel AS p
          ON p.country_code = e.country_code
         AND p.id = e.parcel_id
        JOIN iris_core.source_run AS r
          ON r.country_code = e.country_code
         AND r.id = e.source_run_id
        WHERE p.country_code = 'DE'
          AND p.parcel_ref = 'PARCEL-001'
          AND e.evidence_type = 'peatland_intersection'
          AND e.text_value = 'PEAT-001'
          AND e.numeric_value IS NULL
          AND e.unit IS NULL
          AND r.source_id = 'demo_environment'
          AND r.source_date = DATE '2026-09-01'
    ) THEN
        RAISE EXCEPTION
            'Test failed: expected peatland-intersection evidence is missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM iris_core.evidence AS e
        JOIN iris_core.parcel AS p
          ON p.country_code = e.country_code
         AND p.id = e.parcel_id
        JOIN iris_core.source_run AS r
          ON r.country_code = e.country_code
         AND r.id = e.source_run_id
        WHERE p.country_code = 'DE'
          AND p.parcel_ref = 'PARCEL-001'
          AND e.evidence_type = 'screening_layer_intersection'
          AND e.text_value = 'SCREEN-001'
          AND e.numeric_value IS NULL
          AND e.unit IS NULL
          AND r.source_id = 'demo_screening'
          AND r.source_date = DATE '2026-09-01'
    ) THEN
        RAISE EXCEPTION
            'Test failed: expected screening-layer evidence is missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM iris_core.evidence AS e
        JOIN iris_core.parcel AS p
          ON p.country_code = e.country_code
         AND p.id = e.parcel_id
        JOIN iris_core.source_run AS r
          ON r.country_code = e.country_code
         AND r.id = e.source_run_id
        WHERE p.country_code = 'DE'
          AND p.parcel_ref = 'PARCEL-001'
          AND e.evidence_type = 'substation_distance'
          AND e.text_value = 'SUB-001'
          AND ABS(e.numeric_value - 143.38) <= 0.01
          AND e.unit = 'm'
          AND r.source_id = 'demo_grid_utm32'
          AND r.source_date = DATE '2026-09-01'
    ) THEN
        RAISE EXCEPTION
            'Test failed: expected substation-distance evidence is missing';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM iris_core.evidence AS e
        JOIN iris_core.parcel AS p
          ON p.country_code = e.country_code
         AND p.id = e.parcel_id
        WHERE p.country_code = 'DE'
          AND p.parcel_ref = 'PARCEL-002'
    ) THEN
        RAISE EXCEPTION
            'Test failed: PARCEL-002 should not have screening evidence';
    END IF;
END
$$;

-- Discard any test-only changes.
ROLLBACK;

\echo 'All IRIS spatial screening and evidence tests passed.'
