-- Spatial verification for the two pilot screening paths.

\pset pager off

\echo '=== Parcel / peatland intersections ==='
SELECT
    p.parcel_ref,
    pt.peatland_ref,
    ST_Intersects(p.geom, pt.geom) AS intersects
FROM iris_core.parcel AS p
CROSS JOIN iris_core.peatland AS pt
WHERE p.country_code = pt.country_code
ORDER BY p.parcel_ref, pt.peatland_ref;

\echo 'Expected: PARCEL-001 intersects PEAT-001; PARCEL-002 does not.'

\echo '=== Parcel / screening-layer intersections ==='
SELECT
    p.parcel_ref,
    sl.layer_ref,
    sl.layer_type,
    ST_Intersects(p.geom, sl.geom) AS intersects
FROM iris_core.parcel AS p
CROSS JOIN iris_core.screening_layer AS sl
WHERE p.country_code = sl.country_code
ORDER BY p.parcel_ref, sl.layer_ref;

\echo 'Expected: PARCEL-001 intersects SCREEN-001.'

\echo '=== Parcel / substation proximity in metres ==='
SELECT
    p.parcel_ref,
    s.substation_ref,
    ROUND(
        ST_Distance(p.geom::geography, s.geom::geography)::numeric,
        2
    ) AS distance_m,
    ST_DWithin(
        p.geom::geography,
        s.geom::geography,
        500
    ) AS within_500m
FROM iris_core.parcel AS p
CROSS JOIN iris_core.substation AS s
WHERE p.country_code = s.country_code
ORDER BY p.parcel_ref, s.substation_ref;

\echo '500 m is a deterministic demo threshold, not an IRIS production rule.'

\echo '=== Persisted evidence matches current spatial results ==='
SELECT
    p.parcel_ref,
    e.evidence_type,
    e.text_value AS related_feature_ref,
    CASE e.evidence_type
        WHEN 'peatland_intersection' THEN EXISTS (
            SELECT 1
            FROM iris_core.peatland AS pt
            WHERE pt.country_code = e.country_code
              AND pt.source_run_id = e.source_run_id
              AND pt.peatland_ref = e.text_value
              AND ST_Intersects(p.geom, pt.geom)
        )
        WHEN 'screening_layer_intersection' THEN EXISTS (
            SELECT 1
            FROM iris_core.screening_layer AS sl
            WHERE sl.country_code = e.country_code
              AND sl.source_run_id = e.source_run_id
              AND sl.layer_ref = e.text_value
              AND ST_Intersects(p.geom, sl.geom)
        )
        WHEN 'substation_distance' THEN EXISTS (
            SELECT 1
            FROM iris_core.substation AS s
            WHERE s.country_code = e.country_code
              AND s.source_run_id = e.source_run_id
              AND s.substation_ref = e.text_value
              AND ST_DWithin(p.geom::geography, s.geom::geography, 500)
              AND e.unit = 'm'
              AND e.numeric_value = ROUND(
                    ST_Distance(p.geom::geography, s.geom::geography)::numeric,
                    2
                  )
        )
        ELSE FALSE
    END AS evidence_matches_spatial_result
FROM iris_core.evidence AS e
JOIN iris_core.parcel AS p
  ON p.country_code = e.country_code
 AND p.id = e.parcel_id
ORDER BY p.parcel_ref, e.evidence_type;

\echo '=== Expected deterministic evidence set ==='
SELECT
    COUNT(*) = 3
        AND COUNT(*) FILTER (WHERE p.parcel_ref = 'PARCEL-001') = 3
        AND COUNT(*) FILTER (WHERE p.parcel_ref = 'PARCEL-002') = 0
        AS expected_evidence_set
FROM iris_core.evidence AS e
JOIN iris_core.parcel AS p
  ON p.country_code = e.country_code
 AND p.id = e.parcel_id;
